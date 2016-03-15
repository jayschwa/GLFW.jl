# version of library to download
const version = v"3.2"
const glfw = "glfw-$version"

# TODO: if the latest version is already installed, don't bother with any of this

# download and compile the library from source
@linux_only begin
    deps_dir = dirname(@__FILE__)
    cd(deps_dir)
    srcdir = joinpath(deps_dir, glfw)
    if isdir(srcdir)
        rm(srcdir, recursive=true)
    end
	run(`git clone https://github.com/glfw/glfw.git $glfw`) # clone it for now, since 3.2 is master!
	map(x->!isdir(x) && mkdir(x), ("builds/$glfw", "usr$WORD_SIZE"))
	try
		info("Building GLFW $version library from source")
		cd("builds/$glfw") do
			options = map(x -> "-D$(x[1])=$(x[2])", [
				("BUILD_SHARED_LIBS",    "ON"),
				("CMAKE_INSTALL_PREFIX", "../../usr$WORD_SIZE"),
				("GLFW_BUILD_DOCS",      "OFF"),
				("GLFW_BUILD_EXAMPLES",  "OFF"),
				("GLFW_BUILD_TESTS",     "OFF")
			])
            println(isdir("../../$glfw"))
			run(`cmake $options ../../$glfw`)
			run(`make install`)
		end
	catch e
		warn(e)
		warn("""
On Linux, you might not have xorg-dev and libglu1-mesa-dev installed, which you can get via the commandline with for example
sudo apt-get install  xorg-dev libglu1-mesa-dev
If that doesn't help, try to install GLFW manually
(see http://www.glfw.org/download.html for more information)""")
	end
end

# download a pre-compiled binary (built by Bintray for Homebrew)
@osx_only begin
	const osx_version = convert(VersionNumber, readall(`sw_vers -productVersion`))
	if osx_version >= v"10.11"
		codename = "el_capitan"
	elseif osx_version >= v"10.10"
		codename = "yosemite"
	else
		codename = "mavericks"
	end
	const tarball = "glfw3-$version.$codename.bottle.tar.gz"
	if (!isfile("downloads/$tarball"))
		info("Downloading pre-compiled GLFW $version binary")
		mkpath("downloads")
		download("https://homebrew.bintray.com/bottles-versions/$tarball", "downloads/$tarball")
	end
	mkpath("builds")
	run(`tar xzf downloads/$tarball -C builds`)
	mkpath("usr64")
	cp("builds/glfw3/$version/lib", "usr64/lib", remove_destination=true)
end

# download a pre-compiled binary (built by GLFW)
@windows_only begin
	mkpath("downloads")
	for (sz, suffix) in ((32, ""), (64, "-w64"))
		const build = "$glfw.bin.WIN$sz"
		const archive = "downloads/$build.zip"
		if !isfile(archive)
			info("Downloading pre-compiled GLFW $version $sz-bit binary")
			download("https://github.com/glfw/glfw/releases/download/$version/$build.zip", archive)
		end
		run(`7z x -obuilds -y $archive`)
		dllpath = "builds/$build/lib-mingw$suffix"
		mkpath("usr$sz")
		cp(dllpath, "usr$sz/lib", remove_destination=true)
	end
end
