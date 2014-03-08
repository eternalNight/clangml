#ifndef CLANG_REF_H
#define CLANG_REF_H

#include "ocaml++.h"

template<typename Node>
struct clang_ref
{
  size_t id;

  clang_ref ()
    : id (-1)
  {
  }

  clang_ref (size_t id)
    : id (id)
  {
    if (id == 0)
      throw std::runtime_error ("null reference passed to clang API");
    if (id == -1)
      throw std::runtime_error ("invalid reference passed to clang API");
  }
};


template<typename Node>
static inline value
value_of (value_of_context &ctx, clang_ref<Node> ref)
{
  return value_of (ctx, ref.id);
}

#endif /* CLANG_REF_H */
