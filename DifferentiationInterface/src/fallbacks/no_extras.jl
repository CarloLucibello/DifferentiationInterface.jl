for op in (:derivative, :gradient, :jacobian)
    op! = Symbol(op, "!")
    val_prefix = "value_and_"
    val_and_op = Symbol(val_prefix, op)
    val_and_op! = Symbol(val_prefix, op!)
    prep_op = Symbol("prepare_", op)
    # 1-arg
    @eval function $op(f::F, backend::AbstractADType, x) where {F}
        ex = $prep_op(f, backend, x)
        return $op(f, ex, backend, x)
    end
    @eval function $op!(f::F, result, backend::AbstractADType, x) where {F}
        ex = $prep_op(f, backend, x)
        return $op!(f, result, ex, backend, x)
    end
    @eval function $val_and_op(f::F, backend::AbstractADType, x) where {F}
        ex = $prep_op(f, backend, x)
        return $val_and_op(f, ex, backend, x)
    end
    @eval function $val_and_op!(f::F, result, backend::AbstractADType, x) where {F}
        ex = $prep_op(f, backend, x)
        return $val_and_op!(f, result, ex, backend, x)
    end
    op == :gradient && continue
    # 2-arg
    @eval function $op(f!::F, y, backend::AbstractADType, x) where {F}
        ex = $prep_op(f!, y, backend, x)
        return $op(f!, y, ex, backend, x)
    end
    @eval function $op!(f!::F, y, result, backend::AbstractADType, x) where {F}
        ex = $prep_op(f!, y, backend, x)
        return $op!(f!, y, result, ex, backend, x)
    end
    @eval function $val_and_op(f!::F, y, backend::AbstractADType, x) where {F}
        ex = $prep_op(f!, y, backend, x)
        return $val_and_op(f!, y, ex, backend, x)
    end
    @eval function $val_and_op!(f!::F, y, result, backend::AbstractADType, x) where {F}
        ex = $prep_op(f!, y, backend, x)
        return $val_and_op!(f!, y, result, ex, backend, x)
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
        ex = $prep_op(f, backend, x)
        return $op(f, ex, backend, x)
    end
    @eval function $op!(f::F, result2, backend::AbstractADType, x) where {F}
        ex = $prep_op(f, backend, x)
        return $op!(f, result2, ex, backend, x)
    end
    @eval function $val_and_op(f::F, backend::AbstractADType, x) where {F}
        ex = $prep_op(f, backend, x)
        return $val_and_op(f, ex, backend, x)
    end
    @eval function $val_and_op!(
        f::F, result1, result2, backend::AbstractADType, x
    ) where {F}
        ex = $prep_op(f, backend, x)
        return $val_and_op!(f, result1, result2, ex, backend, x)
    end
end

for op in (:pushforward, :pullback, :hvp)
    op! = Symbol(op, "!")
    val_prefix = "value_and_"
    val_and_op = Symbol(val_prefix, op)
    val_and_op! = Symbol(val_prefix, op!)
    prep_op = Symbol("prepare_", op)
    prep_op_same_point = Symbol("prepare_", op, "_same_point")
    E = if startswith(string(op), "pushforward")
        PushforwardExtras
    elseif startswith(string(op), "pullback")
        PullbackExtras
    elseif startswith(string(op), "hvp")
        HVPExtras
    end
    # 1-arg
    @eval function $prep_op_same_point(f::F, backend::AbstractADType, x, seed) where {F}
        ex = $prep_op(f, backend, x, seed)
        return $prep_op_same_point(f, ex, backend, x, seed)
    end
    @eval function $prep_op_same_point(
        f::F, ex::$E, backend::AbstractADType, x, seed
    ) where {F}
        return ex
    end
    @eval function $op(f::F, backend::AbstractADType, x, seed) where {F}
        ex = $prep_op(f, backend, x, seed)
        return $op(f, ex, backend, x, seed)
    end
    @eval function $op!(f::F, result, backend::AbstractADType, x, seed) where {F}
        ex = $prep_op(f, backend, x, seed)
        return $op!(f, result, ex, backend, x, seed)
    end
    op == :hvp && continue
    @eval function $val_and_op(f::F, backend::AbstractADType, x, seed) where {F}
        ex = $prep_op(f, backend, x, seed)
        return $val_and_op(f, ex, backend, x, seed)
    end
    @eval function $val_and_op!(f::F, result, backend::AbstractADType, x, seed) where {F}
        ex = $prep_op(f, backend, x, seed)
        return $val_and_op!(f, result, ex, backend, x, seed)
    end
    # 2-arg
    @eval function $prep_op_same_point(f!::F, y, backend::AbstractADType, x, seed) where {F}
        ex = $prep_op(f!, y, backend, x, seed)
        return $prep_op_same_point(f!, y, ex, backend, x, seed)
    end
    @eval function $prep_op_same_point(
        f!::F, y, ex::$E, backend::AbstractADType, x, seed
    ) where {F}
        return ex
    end
    @eval function $op(f!::F, y, backend::AbstractADType, x, seed) where {F}
        ex = $prep_op(f!, y, backend, x, seed)
        return $op(f!, y, ex, backend, x, seed)
    end
    @eval function $op!(f!::F, y, result, backend::AbstractADType, x, seed) where {F}
        ex = $prep_op(f!, y, backend, x, seed)
        return $op!(f!, y, result, ex, backend, x, seed)
    end
    @eval function $val_and_op(f!::F, y, backend::AbstractADType, x, seed) where {F}
        ex = $prep_op(f!, y, backend, x, seed)
        return $val_and_op(f!, y, ex, backend, x, seed)
    end
    @eval function $val_and_op!(
        f!::F, y, result, backend::AbstractADType, x, seed
    ) where {F}
        ex = $prep_op(f!, y, backend, x, seed)
        return $val_and_op!(f!, y, result, ex, backend, x, seed)
    end
end
