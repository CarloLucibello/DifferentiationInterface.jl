## Preparation

"""
    PullbackExtras

Abstract type for additional information needed by pullback operators.
"""
abstract type PullbackExtras <: Extras end

struct NoPullbackExtras <: PullbackExtras end

"""
    prepare_pullback(f, backend, x) -> extras
    prepare_pullback(f!, backend, y, x) -> extras

Create an `extras` object subtyping [`PullbackExtras`](@ref) that can be given to pullback operators.
"""
prepare_pullback(f, ::AbstractADType, x) = NoPullbackExtras()
prepare_pullback(f!, ::AbstractADType, y, x) = NoPullbackExtras()

## Allocating

"""
    value_and_pullback(f, backend, x, dy, [extras]) -> (y, dx)

!!! info
    Required primitive for reverse mode backends to support allocating functions.
"""
function value_and_pullback(
    f,
    backend::AbstractADType,
    x,
    dy,
    extras::PullbackExtras=prepare_pullback(f, backend, x),
)
    new_extras = prepare_pushforward(f, backend, x)
    y = f(x)
    dx = if x isa Number && y isa Number
        dy * pushforward(f, backend, x, one(x), new_extras)
    elseif x isa Number && y isa AbstractArray
        dot(dy, pushforward(f, backend, x, one(x), new_extras))
    elseif x isa AbstractArray && y isa Number
        map(CartesianIndices(x)) do j
            dy * pushforward(f, backend, x, basis(backend, x, j), new_extras)
        end
    elseif x isa AbstractArray && y isa AbstractArray
        map(CartesianIndices(x)) do j
            dot(dy, pushforward(f, backend, x, basis(backend, x, j), new_extras))
        end
    end
    return y, dx
end

"""
    value_and_pullback!!(f, dx, backend, x, dy, [extras]) -> (y, dx)
"""
function value_and_pullback!!(
    f,
    dx,
    backend::AbstractADType,
    x,
    dy,
    extras::PullbackExtras=prepare_pullback(f, backend, x),
)
    return value_and_pullback(f, backend, x, dy, extras)
end

"""
    pullback(f, backend, x, dy, [extras]) -> dx
"""
function pullback(
    f,
    backend::AbstractADType,
    x,
    dy,
    extras::PullbackExtras=prepare_pullback(f, backend, x),
)
    return value_and_pullback(f, backend, x, dy, extras)[2]
end

"""
    pullback!!(f, dx, backend, x, dy, [extras]) -> dx
"""
function pullback!!(
    f,
    dx,
    backend::AbstractADType,
    x,
    dy,
    extras::PullbackExtras=prepare_pullback(f, backend, x),
)
    return value_and_pullback!!(f, dx, backend, x, dy, extras)[2]
end

## Mutating

"""
    value_and_pullback!!(f!, y, dx, backend, x, dy, [extras]) -> (y, dx)

!!! info
    Required primitive for reverse mode backends to support mutating functions.
"""
function value_and_pullback!!(
    f!,
    y,
    dx,
    backend::AbstractADType,
    x,
    dy,
    extras::PullbackExtras=prepare_pullback(f!, backend, y, x),
)
    new_extras = prepare_pushforward(f!, backend, y, x)
    dx = if x isa Number && y isa AbstractArray
        dot(dy, value_and_pushforward!!(f!, y, similar(y), backend, x, one(x), new_extras)[2])
    elseif x isa AbstractArray && y isa AbstractArray
        map(CartesianIndices(x)) do j
            dot(
                dy,
                value_and_pushforward!!(
                    f!, y, similar(y), backend, x, basis(backend, x, j), new_extras
                )[2],
            )
        end
    end
    return y, dx
end

## Closure

"""
    value_and_pullback_split(f, backend, x, [extras])

Apply split reverse mode autodiff.

Returns a tuple `(y, pullbackfunc)` where the second element is a function (closure) with the following signature:

    pullbackfunc(dy) -> dx
"""
function value_and_pullback_split(
    f, backend::AbstractADType, x, extras::PullbackExtras=prepare_pullback(f, backend, x)
)
    pullbackfunc(dy) = pullback(f, backend, x, dy, extras)
    return f(x), pullbackfunc
end

"""
    value_and_pullback!!_split(f, backend, x, [extras])

Apply split reverse mode autodiff.

Returns a tuple `(y, pullbackfunc!!)` where the second element is a function (closure) with the following signature:

    pullbackfunc!!(dx, dy) -> dx
"""
function value_and_pullback!!_split(
    f, backend::AbstractADType, x, extras::PullbackExtras=prepare_pullback(f, backend, x)
)
    pullbackfunc!!(dx, dy) = pullback!!(f, dx, backend, x, dy, extras)
    return f(x), pullbackfunc!!
end

"""
    value_and_pullback!!_split(f!, y, backend, x, [extras])

Apply split reverse mode autodiff.

Returns a tuple `(y, pullbackfunc!!)` where the second element is a function (closure) with the following signature:

    pullbackfunc!!(y, dx, dy) -> dx
"""
function value_and_pullback!!_split(
    f!,
    y,
    backend::AbstractADType,
    x,
    extras::PullbackExtras=prepare_pullback(f!, backend, y, x),
)
    function pullbackfunc!!(y, dx, dy)
        return value_and_pullback!!(f!, y, dx, backend, x, dy, extras)[2]
    end
    f!(y, x)
    return y, pullbackfunc!!
end