#ifndef OCAMLPP_H
#define OCAMLPP_H

#include <cassert>
#include <climits>
#include <tuple>
#include <vector>

#include <boost/intrusive_ptr.hpp>
#include <boost/implicit_cast.hpp>
#include <type_traits>

#define O_BEGIN_DECLS	extern "C" {
#define O_END_DECLS	}
#define O_EXPORT	extern "C" __attribute__ ((__visibility__ ("default")))

O_BEGIN_DECLS
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
O_END_DECLS

#include <clang/Basic/SourceLocation.h>
#include <llvm/ADT/StringRef.h>

using boost::implicit_cast;

template<typename T>
using ptr = boost::intrusive_ptr<T>;

template<typename Derived>
struct OCamlADT;

/********************************************************
 * Value construction context.
 */

class value_of_context
{
  value_of_context (value_of_context const &other) = delete;
  value_of_context &operator = (value_of_context const &other) = delete;

  struct data;
  data *self;

  void resize (size_t type, size_t max_id);
  value get (size_t type) const;

public:
  value_of_context ();
  ~value_of_context ();

  template<typename T>
  void resize (ptr<T> const &p)
  {
    resize (p->class_type_id, p->id ());
  }

  data const *operator -> ();

  template<typename T>
  value get () const
  {
    return get (OCamlADT<T>::class_type_id);
  }

  void postpone (std::function<void ()> fun);
  void finish ();

  template<typename T>
  value to_value (T p)
  {
    CAMLparam0 ();
    CAMLlocal1 (v);

    v = p->to_value (*this);
    finish ();

    CAMLreturn (v);
  }
};



// Base class for all ADT types.
struct OCamlADTBase
{
  friend class value_of_context;

private:
  virtual value ToValue (value_of_context &ctx) const = 0;

  virtual size_t type_id   () const = 0;
  virtual size_t local_id  () const = 0;

protected:
  static size_t class_init (std::type_info const &ti);

public:
  static size_t num_type_ids;
  static std::vector<size_t> num_local_ids;

public:
  virtual mlsize_t size () const = 0;
  virtual tag_t tag () const = 0;

  OCamlADTBase ();
  virtual ~OCamlADTBase () { }

  int refcnt = 0;

  static void reset_statistics ();
  static void print_statistics ();

  static size_t values_created;

  static size_t num_global_ids;

  size_t id () const;

  static size_t bytes_allocated;

  value to_value (value_of_context &ctx) const;

  void *operator new (size_t size);
  void operator delete (void *ptr);
};


template<typename Derived>
struct OCamlADT
  : OCamlADTBase
{
public:
  static size_t const class_type_id;
  size_t type_id  () const final { return class_type_id ; }

public:
  size_t const class_local_id = num_local_ids.at (class_type_id)++;
  size_t local_id () const final { return class_local_id; }
};


// OCaml bridge object.
typedef ptr<OCamlADTBase> adt_ptr;


// List of OCaml bridge objects.
template<typename T>
using list = std::vector<ptr<T>>;

typedef list<OCamlADTBase> adt_list;


// OCaml option type.
template<typename T, bool is_adt = std::is_base_of<OCamlADTBase, T>::value>
struct option;

// Specialisation for OCaml bridge object options.
template<typename T>
struct option<T, true>
  : private ptr<T> // don't allow conversion from option to ptr
{
  using ptr<T>::ptr;
#if BOOST_VERSION >= 105400
  using ptr<T>::operator bool;
#else
  explicit operator bool () const { return this->get(); }
#endif

  using ptr<T>::operator ->;

  value to_value (value_of_context &ctx) const
  {
    return (*this)->to_value (ctx);
  }
};

// Implementation for all other option types.
template<typename T>
struct option<T, false>
{
private:
  T ob;
  bool some;

public:
  option ()
    : some (false)
  { }

  option (T value)
    : ob (value)
    , some (true)
  { }

  option &operator = (T value)
  {
    ob = value;
    some = true;
    return *this;
  }

  explicit operator bool () const { return some; }

  value to_value (value_of_context &ctx) const;
};

typedef option<OCamlADTBase> adt_option;

static inline void
intrusive_ptr_add_ref (OCamlADTBase *p)
{
  ++p->refcnt;
}

static inline void
intrusive_ptr_release (OCamlADTBase *p)
{
  if (--p->refcnt == 0)
    delete p;
}


/********************************************************
 * Recursive pointer, actually translated to an index in
 * a global immutable array of T, as to allow recursion in
 * purely functional data structures.
 */
template<typename T>
struct recursive_ptr;

template<typename T>
struct recursive_ptr<ptr<T>>
  : private ptr<T> // don't allow conversion from recursive_ptr to ptr
{
  using ptr<T>::ptr;
#if BOOST_VERSION >= 105400
  using ptr<T>::operator bool;
#else
  explicit operator bool () const { return this->get(); }
#endif
  using ptr<T>::operator ->;
  using ptr<T>::operator =;
};


/********************************************************
 * Forward declarations.
 */

// Recursive entry-point for OCamlADTBase::to_value.
template<typename OCamlADT, typename... Args>
value value_of_adt (value_of_context &ctx, adt_ptr self, Args const &...v);


// Create an OCaml list from a C++ iterator range.
template<typename Iterator>
value value_of_range (value_of_context &ctx, Iterator begin, Iterator end);


/********************************************************
 * value_of
 */

template<typename T>
static inline value
value_of (value_of_context &ctx, std::vector<T> const &v)
{
  return value_of_range (ctx, v.begin (), v.end ());
}


// Non-null pointer.
template<typename T>
typename std::enable_if<std::is_base_of<OCamlADTBase, T>::value, value>::type
// TODO: enable_if_t when C++14 arrives
value_of (value_of_context &ctx, ptr<T> ob)
{
  assert (ob);
  return ob->to_value (ctx);
}

// Nullable pointer.
template<typename T>
value
value_of (value_of_context &ctx, option<T> ob)
{
  CAMLparam0 ();
  CAMLlocal1 (option);

  option = Val_int (0);
  if (ob)
    {
      option = caml_alloc (1, 0);
      Store_field (option, 0, ob.to_value (ctx));
    }

  CAMLreturn (option);
}

// Index.
template<typename T>
value
value_of (value_of_context &ctx, recursive_ptr<T> ob)
{
  // Ignore return value, it will be in the cache.
  //ob->to_value (ctx);
  ctx.postpone ([ob, &ctx] { ob->to_value (ctx); });

  return Val_int (ob->local_id ());
}


static inline value value_of (value_of_context &ctx, int    v)
{ return Val_int (v); }
static inline value value_of (value_of_context &ctx, size_t v)
{ return Val_int (v); }
static inline value value_of (value_of_context &ctx, double v)
{ return caml_copy_double (v); }
static inline value value_of (value_of_context &ctx, int64_t v)
{ return caml_copy_int64 (v); }

static inline value
value_of (value_of_context &ctx, llvm::StringRef const &v)
{
  CAMLparam0 ();
  CAMLlocal1 (string);

  string = caml_alloc_string (v.size ());
  memcpy (String_val (string), v.data (), v.size ());

  CAMLreturn (string);
}


static inline value
value_of (value_of_context &ctx, clang::SourceLocation v)
{
  unsigned raw = v.getRawEncoding ();
  return caml_copy_int32 (raw);
}


/********************************************************
 * value_of_range implementation.
 */

template<typename Iterator>
value
value_of_range (value_of_context &ctx, Iterator begin, Iterator end)
{
  CAMLparam0 ();
  CAMLlocal3 (start_value, cons_value, tmp_value);

  // It would be much easier to build the list backwards,
  // but we may not have that kind of iterator

  if (begin == end)
    return Val_emptylist;

  start_value = caml_alloc (2, 0);
  // head is first item
  Store_field (start_value, 0, value_of (ctx, *begin));

  cons_value = start_value;

  ++begin;
  for (; begin != end; begin++)
    {
      tmp_value = caml_alloc (2, 0);
      // tail is not yet fully constructed rest of list
      Store_field (cons_value, 1, tmp_value);

      cons_value = tmp_value;
      Store_field (cons_value, 0, value_of (ctx, *begin));
    }

  // tail of last cons is empty list
  Store_field (cons_value, 1, Val_emptylist);

  CAMLreturn (start_value);
}



/********************************************************
 * value_of_adt implementation.
 */

static inline void
store_fields (value_of_context &ctx, value result, int field)
{
  // recursion end
}

template<typename Arg0, typename... Args>
void store_fields (value_of_context &ctx, value &result, int field,
                   Arg0 const &arg0, Args const &...args)
{
  Store_field (result, field, value_of (ctx, arg0));
  store_fields (ctx, result, field + 1, args...);
}


template<typename OCamlADT, typename... Args>
value
value_of_adt (value_of_context &ctx, OCamlADT const *self, Args const &...v)
{
  assert (sizeof... (v) == self->size ());
  CAMLparam0 ();
  CAMLlocal1 (result);

  result = caml_alloc (self->size (), self->tag ());

  store_fields (ctx, result, 0, v...);

  CAMLreturn (result);
}


template<typename OCamlADT>
value
value_of_adt (value_of_context &ctx, OCamlADT const *self)
{
  return Val_int (self->tag ());
}


/********************************************************
 * Tuple support.
 */

template<size_t...>
struct seq
{
};

template<size_t N, size_t... S>
struct make_seq
  : make_seq<N - 1, N - 1, S...>
{
};

template<size_t... S>
struct make_seq<0, S...>
{
  typedef seq<S...> type;
};


template<size_t Index>
void
store_fields (value &result, value_of_context &ctx)
{
  assert (Index == caml_array_length (result));
}

template<size_t Index, typename T, typename... Types>
void
store_fields (value &result, value_of_context &ctx, T const &head, Types const &...tail)
{
  Store_field (result, Index, value_of (ctx, head));
  store_fields<Index + 1> (result, ctx, tail...);
}


template<size_t... Indices, typename... Types>
void
store_fields (seq<Indices...>, value &result, value_of_context &ctx, std::tuple<Types...> const &v)
{
  store_fields<0> (result, ctx, std::get<Indices> (v)...);
}


template<typename... Types>
value
value_of (value_of_context &ctx, std::tuple<Types...> const &v)
{
  CAMLparam0 ();
  CAMLlocal1 (result);

  result = caml_alloc_tuple (sizeof... (Types));
  store_fields (typename make_seq<sizeof... (Types)>::type (), result, ctx, v);

  CAMLreturn (result);
}


/********************************************************
 * option<non-adt>::to_value implementation.
 * Comes last, so all value_ofs are in scope.
 */

template<typename T>
value
option<T, false>::to_value (value_of_context &ctx) const
{
  return value_of (ctx, ob);
}

#endif /* OCAMLPP_H */
