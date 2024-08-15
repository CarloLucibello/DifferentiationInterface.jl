for op in (:derivative, :gradient, :jacobian)
    op! = Symbol(op, "!")
    val_prefix = "value_and_"
    val_and_op = Symbol(val_prefix, op)
    val_and_op! = Symbol(val_prefix, op!)
    prep_op = Symbol("prepare_", op)
    # 1-arg
    @eval function $op(f::F, backend::AbstractADType, x) where {F}
        return $op(f, backend, x, $prep_op(f, backend, x))
    end
    @eval function $op!(f::F, result, backend::AbstractADType, x) where {F}
        return $op!(f, result, backend, x, $prep_op(f, backend, x))
    end
    @eval function $val_and_op(f::F, backend::AbstractADType, x) where {F}
        return $val_and_op(f, backend, x, $prep_op(f, backend, x))
    end
    @eval function $val_and_op!(f::F, result, backend::AbstractADType, x) where {F}
        return $val_and_op!(f, result, backend, x, $prep_op(f, backend, x))
    end
    op == :gradient && continue
    # 2-arg
    @eval function $op(f!::F, y, backend::AbstractADType, x) where {F}
        return $op(f!, y, backend, x, $prep_op(f!, y, backend, x))
    end
    @eval function $op!(f!::F, y, result, backend::AbstractADType, x) where {F}
        return $op!(f!, y, result, backend, x, $prep_op(f!, y, backend, x))
    end
    @eval function $val_and_op(f!::F, y, backend::AbstractADType, x) where {F}
        return $val_and_op(f!, y, backend, x, $prep_op(f!, y, backend, x))
    end
    @eval function $val_and_op!(f!::F, y, result, backend::AbstractADType, x) where {F}
        return $val_and_op!(f!, y, result, backend, x, $prep_op(f!, y, backend, x))
    end
end

for op in (:second_derivative, :hessian)
    op! = Symbol(op, "!")
    val_prefix = if op == :second_derivative
        "value_derivative_and_"
    elseif op == :hessian
        "value_gradient_and_"
    end
    val_and_op = Symbol(val_prefix, op)
    val_and_op! = Symbol(val_prefix, op!)
    prep_op = Symbol("prepare_", op)
    # 1-arg
    @eval function $op(f::F, backend::AbstractADType, x) where {F}
        return $op(f, backend, x, $prep_op(f, backend, x))
    end
    @eval function $op!(f::F, result2, backend::AbstractADType, x) where {F}
        return $op!(f, result2, backend, x, $prep_op(f, backend, x))
    end
    @eval function $val_and_op(f::F, backend::AbstractADType, x) where {F}
        return $val_and_op(f, backend, x, $prep_op(f, backend, x))
    end
    @eval function $val_and_op!(
        f::F, result1, result2, backend::AbstractADType, x
    ) where {F}
        return $val_and_op!(f, result1, result2, backend, x, $prep_op(f, backend, x))
    end
end

for op in
    (:pushforward, :pushforward_batched, :pullback, :pullback_batched, :hvp, :hvp_batched)
    op! = Symbol(op, "!")
    val_prefix = "value_and_"
    val_and_op = Symbol(val_prefix, op)
    val_and_op! = Symbol(val_prefix, op!)
    prep_op = Symbol("prepare_", op)
    # 1-arg
    @eval function $op(f::F, backend::AbstractADType, x, seed) where {F}
        return $op(f, backend, x, seed, $prep_op(f, backend, x, seed))
    end
    @eval function $op!(f::F, result, backend::AbstractADType, x, seed) where {F}
        return $op!(f, result, backend, x, seed, $prep_op(f, backend, x, seed))
    end
    op == :hvp && continue
    # 2-arg
    @eval function $val_and_op(f::F, backend::AbstractADType, x, seed) where {F}
        return $val_and_op(f, backend, x, seed, $prep_op(f, backend, x, seed))
    end
    @eval function $val_and_op!(f::F, result, backend::AbstractADType, x, seed) where {F}
        return $val_and_op!(f, result, backend, x, seed, $prep_op(f, backend, x, seed))
    end
    @eval function $op(f!::F, y, backend::AbstractADType, x, seed) where {F}
        return $op(f!, y, backend, x, seed, $prep_op(f!, y, backend, x, seed))
    end
    @eval function $op!(f!::F, y, result, backend::AbstractADType, x, seed) where {F}
        return $op!(f!, y, result, backend, x, seed, $prep_op(f!, y, backend, x, seed))
    end
    @eval function $val_and_op(f!::F, y, backend::AbstractADType, x, seed) where {F}
        return $val_and_op(f!, y, backend, x, seed, $prep_op(f!, y, backend, x, seed))
    end
    @eval function $val_and_op!(
        f!::F, y, result, backend::AbstractADType, x, seed
    ) where {F}
        return $val_and_op!(
            f!, y, result, backend, x, seed, $prep_op(f!, y, backend, x, seed)
        )
    end
end