
"""
Write model configurations to options file (OPS.h).
"""
function write_modcfg(modcfg)

    info("Writing model configs (opts.h)")

    str = """
    /* Process options */
    #define ALBEDO $(modcfg["albedo"])  /* snow albedo: 0 - diagnostic, 1 - prognostic                          */
    #define CANMOD $(modcfg["canmod"])  /* forest canopy: 0 - zero layer, 1 - one layer                         */
    #define CONDCT $(modcfg["condct"])  /* snow thermal conductivity: 0 - constant, 1 - Yen (1981)              */
    #define DENSTY $(modcfg["densty"])  /* snow density: 0 - constant, 1 - Verseghy (1991), 2 - Anderson (1976) */
    #define EXCHNG $(modcfg["exchng"])  /* turbulent exchange: 0 - constant, 1 - Louis (1979)                   */
    #define HYDROL $(modcfg["hydrol"])  /* snow hydraulics: 0 - free draining, 1 - bucket                       */

    /* Driving data options */
    #define DRIV1D 0   /* 1D driving data format: 0 - FSM, 1 - ESM-SnowMIP                  */
    #define DOWNSC 0   /* 1D driving data downscaling: 0 - no, 1 - yes                      */
    #define DEMHDR 0   /* DEM header: 0 - none, 1 - ESRI format                             */
    #define SWPART 0   /* SW radiation: 0 - total, 1 - direct and diffuse calculated        */
    #define ZOFFST 1   /* Measurement height offset: 0 - above ground, 1 - above canopy top */
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
                "EBALSRF.F90", "FSMNC.F90", "LUDCMP.F90", "OUTPUTNC.F90", "PHYSICS.F90", "QSAT.F90",
                "RADIATION.F90", "READMAPS.F90", "SETUPNC.F90", "SNOW.F90", "SOIL.F90", "SFEXCH.F90",
                "THERMAL.F90", "TRIDIAG.F90"]

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

        @info "Compiling configuration $(icfg)"

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

