module PaperPlot

using Plots, Statistics

export paperplot

get_quantile(A::AbstractArray, p; dims) = mapslices(x->quantile(x, p), A, dims=dims)
squeeze(A) = reshape(A, Tuple(i for i in size(A) if i != 1))

function paperplot(
    fz,
    measures_per_it,
    labels   = ["SPSA", "CSPSA", "2-SPSA", "2-CSPSA", "QN-SPSA", "QN-CSPSA"],
    lines    = Dict(:real => (2, "blue"), :comp => (2, "red")),
    ylabel   = "Infidelity",
    xlabel   = "Measurements";
    plotargs...
    )

    # Get statistics
    fmean = [mean(fz_opt, dims=2) |> squeeze for fz_opt in fz]
    fvar  = [ var(fz_opt, dims=2) |> squeeze for fz_opt in fz]

    fmedian = [median(fz_opt, dims=2) |> squeeze for fz_opt in fz]
    iqr     = [(get_quantile(fz_opt, 0.25, dims=2) |> squeeze,
                get_quantile(fz_opt, 0.75, dims=2) |> squeeze) for fz_opt in fz]


    # Number of iterations per optimizer
    Niters = [ length(f) for f in fmean ]
    xaxes = Base.OneTo.(Niters) .* measures_per_it

    # Plot mean and var
    plots = [plot() for i in 1:6]
    plot!(plots[1], ylabel=ylabel*" (mean)", leftmargin = 5Plots.mm)
    plot!.(plots[2:3], yformatter=_->"", leftmargin = -5Plots.mm)
    for i in 1:3
        plot!(plots[i], xaxes[2i-1], fmean[2i-1], ribbon=fvar[2i-1], line=lines[:real], label=labels[2i-1])
        plot!(plots[i], xaxes[ 2i ], fmean[ 2i ], ribbon=fvar[ 2i ], line=lines[:comp], label=labels[ 2i ])
    end

    # Plot median and iqr
    plot!(plots[4], ylabel=ylabel*" (median)", leftmargin = 5Plots.mm)
    plot!.(plots[5:6], yformatter=_->"")# , leftmargin = -5Plots.mm)
    for i in 1:3
        plot!(plots[i+3], xaxes[2i-1], fmedian[2i-1], ribbon=iqr[2i-1], line=lines[:real], label=labels[2i-1])
        plot!(plots[i+3], xaxes[ 2i ], fmedian[ 2i ], ribbon=iqr[ 2i ], line=lines[:comp], label=labels[ 2i ])
    end

    # Titles
    plot!(plots[1], title = "First order")
    plot!(plots[2], title = "Second order")
    plot!(plots[3], title = "Quantum Natural")

    # xlabels
    plot!.(plots[1:3], xformatter=_->"")
    plot!.(plots[4:6], xlabel=xlabel)

    # Margins
    # plot!.(plots[1:3], bottom_margin=-3Plots.mm)
    plot!.(plots[4:6], bottom_margin=5Plots.mm)

    # Combine all plots
    plot_combined = plot(plots...,
                         xlim=(1, minimum(Niters .* measures_per_it)),
                         layout = (2, 3),
                         yscale = :log10,
                         yticks = 10.0 .^ (-6:0),
                         legend = :false,
                         link = :both,
                         grid = true,
                         fontfamily = "serif-roman",
                         size = (1200, 500),
                         ;
                         plotargs...
                         )

    return plot_combined

end


end
