struct SparseDiffToolsAllocatingJacobianExtras{C} <: JacobianExtras
    cache::C
end

for AutoSparse in SPARSE_BACKENDS
    @eval begin

        ## Jacobian

        function DI.prepare_jacobian(f, backend::$AutoSparse, x::AbstractArray)
            cache = sparse_jacobian_cache(
                backend, SymbolicsSparsityDetection(), f, x; fx=f(x)
            )
            return SparseDiffToolsAllocatingJacobianExtras(cache)
        end

        function DI.value_and_jacobian!!(
            f, jac, backend::$AutoSparse, x, extras::SparseDiffToolsAllocatingJacobianExtras
        )
            sparse_jacobian!(jac, backend, extras.cache, f, x)
            return f(x), jac
        end

        function DI.jacobian!!(
            f, jac, backend::$AutoSparse, x, extras::SparseDiffToolsAllocatingJacobianExtras
        )
            sparse_jacobian!(jac, backend, extras.cache, f, x)
            return jac
        end

        function DI.value_and_jacobian(
            f, backend::$AutoSparse, x, extras::SparseDiffToolsAllocatingJacobianExtras
        )
            return f(x), sparse_jacobian(backend, extras.cache, f, x)
        end

        function DI.jacobian(
            f, backend::$AutoSparse, x, extras::SparseDiffToolsAllocatingJacobianExtras
        )
            return sparse_jacobian(backend, extras.cache, f, x)
        end
    end
end