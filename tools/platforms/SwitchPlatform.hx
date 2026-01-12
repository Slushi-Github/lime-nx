package;

import lime.tools.HashlinkHelper;
import hxp.Haxelib;
import hxp.HXML;
import hxp.Path;
import hxp.Log;
import hxp.NDLL;
import hxp.System;
import lime.tools.Architecture;
import lime.tools.AssetHelper;
import lime.tools.AssetType;
import lime.tools.CPPHelper;
import lime.tools.DeploymentHelper;
import lime.tools.HXProject;
import lime.tools.JavaHelper;
import lime.tools.NekoHelper;
import lime.tools.NodeJSHelper;
import lime.tools.Orientation;
import lime.tools.Platform;
import lime.tools.PlatformTarget;
import lime.tools.ProjectHelper;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class SwitchPlatform extends PlatformTarget
{
	private var applicationDirectory:String;
	private var executablePath:String;
	private var is64:Bool;
	private var isRaspberryPi:Bool;
	private var targetType:String;

	public function new(command:String, _project:HXProject, targetFlags:Map<String, String>)
	{
		super(command, _project, targetFlags);

		Sys.println("Switch Platform!!!!");
		Sys.println("Switch Platform!!!!");
		Sys.println("Switch Platform!!!!");

		var defaults = new HXProject();

		defaults.meta =
			{
				title: "MyApplication",
				description: "",
				packageName: "com.example.myapp",
				version: "1.0.0",
				company: "",
				companyUrl: "",
				buildNumber: null,
				companyId: ""
			};

		defaults.app =
			{
				main: "Main",
				file: "MyApplication",
				path: "bin",
				preloader: "",
				swfVersion: 17,
				url: "",
				init: null
			};

		defaults.window =
			{
				width: 800,
				height: 600,
				parameters: "{}",
				background: 0xFFFFFF,
				fps: 30,
				hardware: true,
				display: 0,
				resizable: true,
				borderless: false,
				orientation: Orientation.AUTO,
				vsync: false,
				fullscreen: false,
				allowHighDPI: true,
				alwaysOnTop: false,
				antialiasing: 0,
				allowShaders: true,
				requireShaders: false,
				depthBuffer: true,
				stencilBuffer: true,
				colorDepth: 32,
				maximized: false,
				minimized: false,
				hidden: false,
				title: ""
			};

		
		defaults.architectures = [ARM64];

		defaults.window.allowHighDPI = false;

		for (i in 1...project.windows.length)
		{
			defaults.windows.push(defaults.window);
		}

		defaults.merge(project);
		project = defaults;

		for (excludeArchitecture in project.excludeArchitectures)
		{
			project.architectures.remove(excludeArchitecture);
		}

		
		is64 = true;
		

		targetType = "cpp";

		var defaultTargetDirectory = switch (targetType)
		{
			case "cpp": "switch";
			case "hl": project.targetFlags.exists("hlc") ? "hlc" : targetType;
			default: targetType;
		}
		targetDirectory = Path.combine(project.app.path, project.config.getString("switch.output-directory", defaultTargetDirectory));
		targetDirectory = StringTools.replace(targetDirectory, "arch64", is64 ? "64" : "");
		applicationDirectory = targetDirectory + "/bin/";
		executablePath = Path.combine(applicationDirectory, project.app.file);
	}

	public override function build():Void
	{
		var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";

		System.mkdir(targetDirectory);

		if (!project.targetFlags.exists("static") || targetType != "cpp")
		{
			var targetSuffix = (targetType == "hl") ? ".hdll" : null;

			for (ndll in project.ndlls)
			{
				
				ProjectHelper.copyLibrary(project, ndll, "switch", "",
					(ndll.haxelib != null
						&& (ndll.haxelib.name == "hxcpp" || ndll.haxelib.name == "hxlibc")) ? ".dll" : ".ndll", applicationDirectory,
					project.debug, targetSuffix);
				
			}
		}

		else
		{
			var haxeArgs = [hxml];
			var flags = [];

			
			haxeArgs.push("-D");
			haxeArgs.push("HXCPP_ARM64");
			haxeArgs.push("-D");
			haxeArgs.push("nx");
			flags.push("-DHXCPP_ARM64");
			flags.push("-Dnx=1");
			flags.push("-DHX_NX=1");
			flags.push("-D__SWITCH__");

			var hxcpp_xlinux64_cxx = project.defines.get("HXCPP_XLINUX64_CXX");
			if (hxcpp_xlinux64_cxx == null)
			{
				hxcpp_xlinux64_cxx = '${Sys.getEnv("DEVKITPRO")}/devkitA64/aarch64-none-elf-g++';
			}
			var hxcpp_xlinux64_strip = project.defines.get("HXCPP_XLINUX64_STRIP");
			if (hxcpp_xlinux64_strip == null)
			{
				hxcpp_xlinux64_strip = '${Sys.getEnv("DEVKITPRO")}/devkitA64/aarch64-none-elf-strip';
			}
			var hxcpp_xlinux64_ranlib = project.defines.get("HXCPP_XLINUX64_RANLIB");
			if (hxcpp_xlinux64_ranlib == null)
			{
				hxcpp_xlinux64_ranlib = '${Sys.getEnv("DEVKITPRO")}/devkitA64/aarch64-none-elf-ranlib';
			}
			var hxcpp_xlinux64_ar = project.defines.get("HXCPP_XLINUX64_AR");
			if (hxcpp_xlinux64_ar == null)
			{
				hxcpp_xlinux64_ar = '${Sys.getEnv("DEVKITPRO")}/devkitA64/aarch64-none-elf-ar';
			}
			flags.push('-DHXCPP_XLINUX64_CXX=$hxcpp_xlinux64_cxx');
			flags.push('-DHXCPP_XLINUX64_STRIP=$hxcpp_xlinux64_strip');
			flags.push('-DHXCPP_XLINUX64_RANLIB=$hxcpp_xlinux64_ranlib');
			flags.push('-DHXCPP_XLINUX64_AR=$hxcpp_xlinux64_ar');

			if (!project.targetFlags.exists("static"))
			{
				System.runCommand("", "haxe", haxeArgs);

				if (noOutput) return;

				CPPHelper.compile(project, targetDirectory + "/obj", flags);

				System.copyFile(targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), executablePath);
			}
			else
			{
				System.runCommand("", "haxe", haxeArgs.concat(["-D", "static_link"]));

				if (noOutput) return;

				CPPHelper.compile(project, targetDirectory + "/obj", flags.concat(["-Dstatic_link"]));
				CPPHelper.compile(project, targetDirectory + "/obj", flags, "BuildMain.xml");

				System.copyFile(targetDirectory + "/obj/Main" + (project.debug ? "-debug" : ""), executablePath);
			}
		}
	}

	public override function clean():Void
	{
		if (FileSystem.exists(targetDirectory))
		{
			System.removeDirectory(targetDirectory);
		}
	}

	public override function deploy():Void
	{
		DeploymentHelper.deploy(project, targetFlags, targetDirectory, "switch");
	}

	public override function display():Void
	{
		if (project.targetFlags.exists("output-file"))
		{
			Sys.println(executablePath);
		}
		else
		{
			Sys.println(getDisplayHXML().toString());
		}
	}

	private function generateContext():Dynamic
	{
		// var project = project.clone ();

		var context = project.templateContext;

		context.CPP_DIR = targetDirectory + "/obj/";

		return context;
	}

	private function getDisplayHXML():HXML
	{
		var path = targetDirectory + "/haxe/" + buildType + ".hxml";

		// try to use the existing .hxml file. however, if the project file was
		// modified more recently than the .hxml, then the .hxml cannot be
		// considered valid anymore. it may cause errors in editors like vscode.
		if (FileSystem.exists(path)
			&& (project.projectFilePath == null || !FileSystem.exists(project.projectFilePath)
				|| (FileSystem.stat(path).mtime.getTime() > FileSystem.stat(project.projectFilePath).mtime.getTime())))
		{
			return File.getContent(path);
		}
		else
		{
			var context = project.templateContext;
			var hxml = HXML.fromString(context.HAXE_FLAGS);
			hxml.addClassName(context.APP_MAIN);
			
			hxml.cpp = "_";

			hxml.noOutput = true;
			return hxml;
		}
	}

	public override function rebuild():Void
	{
		var commands = [];

		commands.push([
			"-Dnx=1",
			"-DHX_NX=1",
			"-Dstatic",
			// "-Dtoolchain=linux",
			"-DBINDIR=Switch",
			"-DHXCPP_ARM64",
			"-DDEVKITPRO=" + '${Sys.getEnv("DEVKITPRO")}',
			"-DCXX=" + '${Sys.getEnv("DEVKITPRO")}/devkitA64/aarch64-none-elf-g++',
			"-DHXCPP_STRIP=" + '${Sys.getEnv("DEVKITPRO")}/devkitA64/aarch64-none-elf-strip',
			"-DHXCPP_AR=" + '${Sys.getEnv("DEVKITPRO")}/devkitA64/aarch64-none-elf-ar',
			"-DHXCPP_RANLIB=" + '${Sys.getEnv("DEVKITPRO")}/devkitA64/aarch64-none-elf-ranlib'
		]);

		// Sys.println(commands.toString());

		// Sys.println(getDisplayHXML().toString());

		CPPHelper.rebuild(project, commands);
	}

	public override function run():Void
	{
		Sys.println("Use NXLink to run the program.");
	}

	public override function update():Void
	{
		AssetHelper.processLibraries(project, targetDirectory);

		// project = project.clone ();
		// initialize (project);

		for (asset in project.assets)
		{
			if (asset.embed && asset.sourcePath == "")
			{
				var path = Path.combine(targetDirectory + "/obj/tmp", asset.targetPath);
				System.mkdir(Path.directory(path));
				AssetHelper.copyAsset(asset, path);
				asset.sourcePath = path;
			}
		}

		if (project.targetFlags.exists("xml"))
		{
			project.haxeflags.push("-xml " + targetDirectory + "/types.xml");
		}

		var context = generateContext();
		context.OUTPUT_DIR = targetDirectory;

		if (targetType == "cpp" && project.targetFlags.exists("static"))
		{
			for (i in 0...project.ndlls.length)
			{
				var ndll = project.ndlls[i];

				if (ndll.path == null || ndll.path == "")
				{
					context.ndlls[i].path = NDLL.getLibraryPath(ndll, "Linux" + (( System.hostArchitecture == ARMV7 || System.hostArchitecture == ARM64) ? "Arm" : "") + (is64 ? "64" : ""), "lib", ".a", project.debug);
				}
			}
		}

		System.mkdir(targetDirectory);
		System.mkdir(targetDirectory + "/obj");
		System.mkdir(targetDirectory + "/haxe");
		System.mkdir(applicationDirectory);

		// SWFHelper.generateSWFClasses (project, targetDirectory + "/haxe");

		ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", targetDirectory + "/haxe", context);
		ProjectHelper.recursiveSmartCopyTemplate(project, targetType + "/hxml", targetDirectory + "/haxe", context);

		if (targetType == "cpp" && project.targetFlags.exists("static"))
		{
			ProjectHelper.recursiveSmartCopyTemplate(project, "cpp/static", targetDirectory + "/obj", context);
		}

		// context.HAS_ICON = IconHelper.createIcon (project.icons, 256, 256, Path.combine (applicationDirectory, "icon.png"));
		for (asset in project.assets)
		{
			var path = Path.combine(applicationDirectory, asset.targetPath);

			if (asset.embed != true)
			{
				if (asset.type != AssetType.TEMPLATE)
				{
					System.mkdir(Path.directory(path));
					AssetHelper.copyAssetIfNewer(asset, path);
				}
				else
				{
					System.mkdir(Path.directory(path));
					AssetHelper.copyAsset(asset, path, context);
				}
			}
		}
	}

	public override function watch():Void
	{
		var hxml = getDisplayHXML();
		var dirs = hxml.getClassPaths(true);

		var outputPath = Path.combine(Sys.getCwd(), project.app.path);
		dirs = dirs.filter(function(dir)
		{
			return (!Path.startsWith(dir, outputPath));
		});

		var command = ProjectHelper.getCurrentCommand();
		System.watch(command, dirs);
	}

	@ignore public override function install():Void {}

	@ignore public override function trace():Void {}

	@ignore public override function uninstall():Void {}
}
