
"""
Write model configurations to options file (OPS.h).
"""
function write_modcfg(modcfg)

    info("Writing model configs (opts.h)")

    str = """
    #define ALBEDO $(modcfg["albedo"])
    #define CANMOD $(modcfg["canmod"])
    #define CONDCT $(modcfg["condct"])
    #define DENSTY $(modcfg["densty"])
    #define EXCHNG $(modcfg["exchng"])
    #define HYDROL $(modcfg["hydrol"])

    #define DRIV1D 0
    #define SWPART 1

    #if ALBEDO == 0
    #define ALBEDO_OPT 'diagnostic'
    #elif ALBEDO == 1
    #define ALBEDO_OPT 'prognostic'
    #endif

    #if CANMOD == 0
    #define CANMOD_OPT 'zero layer'
    #elif CANMOD == 1
    #define CANMOD_OPT 'one layer'
    #endif

    #if CONDCT == 0
    #define CONDCT_OPT 'constant'
    #elif CONDCT == 1
    #define CONDCT_OPT 'Yen (1981)'
    #endif

    #if DENSTY == 0
    #define DENSTY_OPT 'constant'
    #elif DENSTY == 1
    #define DENSTY_OPT 'Verseghy (1991)'
    #endif

    #if EXCHNG == 0
    #define EXCHNG_OPT 'constant'
    #elif EXCHNG == 1
    #define EXCHNG_OPT 'Louis (1979)'
    #endif

    #if HYDROL == 0
    #define HYDROL_OPT 'free draining'
    #elif HYDROL == 1
    #define HYDROL_OPT 'bucket'
    #endif
    """

    # Write file

    fid = open("OPTS.h", "w")

    write(fid, str)

    close(fid)

    return nothing
    
end


"""
Compile the model for current configuration and netcdf version.
"""
function compile_netcdf(path, modcfg, icfg)

    curr = pwd()

    cd(joinpath(path, "src"))

    write_modcfg(modcfg)
    
    icfg = string(icfg)

    dest = joinpath(path, "bin", "FSM_$(icfg)")

    mods = ["DATANC.F90", "MODULES.F90"]

    routines = ["CANOPY.F90", "CUMULATE.F90", "DRIVENC.F90", "DUMP.F90", "EBALFOR.F90",
                "EBALOPN.F90", "FSMNC.F90", "LUDCMP.F90", "OUTPUTNC.F90", "PHYSICS.F90",
                "QSAT.F90", "READMAPS.F90", "SETUPNC.F90", "SFEXCH.F90", "SNOW.F90", "SOIL.F90",
                "SWRAD.F90", "THERMAL.F90", "TRIDIAG.F90"]

    run(`gfortran -o $dest -O3 $mods $routines -g -O2 -I/usr/include -L/usr/lib -lnetcdff -lnetcdf`)
    
    rm.(filter!(f -> endswith(f, "mod"), readdir()))
    
    cd(curr)

end


"""
Compile the model for current configuration and standard version.
"""
function compile_standard(path, modcfg, icfg)

    curr = pwd()

    cd(joinpath(path, "src"))

    write_modcfg(modcfg)
    
    icfg = string(icfg)

    dest = joinpath(path, "bin", "FSM_$(icfg)")

    mods = ["MODULES.F90"]

    routines = ["CANOPY.F90", "CUMULATE.F90", "DRIVE.F90", "DUMP.F90", "EBALFOR.F90",
                "EBALOPN.F90", "FSM2.F90", "LUDCMP.F90", "OUTPUT.F90", "PHYSICS.F90",
                "QSAT.F90", "READMAPS.F90", "SETUP.F90", "SFEXCH.F90", "SNOW.F90", "SOIL.F90",
                "SWRAD.F90", "THERMAL.F90", "TRIDIAG.F90"]

    run(`gfortran -o $dest -O3 $mods $routines -g -O2`)
    
    rm.(filter!(f -> endswith(f, "mod"), readdir()))
    
    cd(curr)

end


"""
Generate dataframe with configurations.
"""
function cfg_table()

    df = DataFrame(albedo = [],
                   canmod = [],
                   condct = [],
                   densty = [],
                   exchng = [],
                   hydrol = [])
    
    for alb = 0:1, can = 0, con = 0:1, den = 0:1, exh = 0:1, hyd = 0:1
        push!(df, [alb, can, con, den, exh, hyd])
    end

    df[:cfg] = 1:32

    return df
    
end


"""
Compile all configuratins in df_cfg.
"""
function compile_all(path, df_cfg, version)

    icfg = 1

    for row in eachrow(df_cfg)

        info("Compiling configuration $(icfg)")

        modcfg = Dict("albedo" => row[:albedo],
                      "canmod" => row[:canmod],
                      "condct" => row[:condct],
                      "densty" => row[:densty],
                      "exchng" => row[:exchng],
                      "hydrol" => row[:hydrol])

        if version == "netcdf"
            compile_netcdf(path, modcfg, icfg)
        end

        if version == "standard"
            compile_standard(path, modcfg, icfg)
        end
        
        icfg += 1

    end
    
end

