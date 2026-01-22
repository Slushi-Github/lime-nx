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
import lime.tools.haxenxcompiler.SwitchLinker;
import lime.tools.Icon;
import lime.tools.IconHelper;
import lime.graphics.Image;
import lime.graphics.ImageFileFormat;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;
import haxe.Resource;

using StringTools;

class SwitchPlatform extends PlatformTarget
{
    private var applicationDirectory:String;
    private var executablePath:String;
    private var is64:Bool;
    private var targetType:String;

    public function new(command:String, _project:HXProject, targetFlags:Map<String, String>)
    {
        super(command, _project, targetFlags);

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
                path: "export",
                preloader: "",
                swfVersion: 17,
                url: "",
                init: null
            };

        defaults.window =
            {
                width: 1280,
                height: 720,
                parameters: "{}",
                background: 0xFFFFFF,
                fps: 60,
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

        var defaultTargetDirectory = "switch";
        targetDirectory = Path.combine(project.app.path, project.config.getString("switch.output-directory", defaultTargetDirectory));
        targetDirectory = StringTools.replace(targetDirectory, "arch64", is64 ? "64" : "");
        applicationDirectory = targetDirectory + "/bin/";
        executablePath = Path.combine(applicationDirectory, project.app.file);
    }

    private function getLimePath():String
    {
        return Haxelib.getPath(new Haxelib("lime"));
    }

    public override function build():Void
    {
        var hxml = targetDirectory + "/haxe/" + buildType + ".hxml";

        System.mkdir(targetDirectory);

        if (targetType == "cpp")
        {
            var haxeArgs = [hxml];
            var flags = [];

            haxeArgs.push("-D");
            haxeArgs.push("HXCPP_ARM64");
            haxeArgs.push("-D");
            haxeArgs.push("nx");
            haxeArgs.push("-D");
            haxeArgs.push("HX_NX");
            haxeArgs.push("-D");
            haxeArgs.push("static_link");

            flags.push("-DHXCPP_ARM64");
            flags.push("-Dnx=1");
            flags.push("-DHX_NX=1");
            flags.push("-D__SWITCH__");
            flags.push("-D__NX__");

            var dkp = Sys.getEnv("DEVKITPRO");
            if (dkp == null || dkp == "") {
                Log.error("Environment variable DEVKITPRO is not defined.");
                return;
            }

            var hxcpp_xlinux64_cxx = project.defines.get("HXCPP_XLINUX64_CXX");
            if (hxcpp_xlinux64_cxx == null) hxcpp_xlinux64_cxx = '$dkp/devkitA64/bin/aarch64-none-elf-g++';
            
            var hxcpp_xlinux64_strip = project.defines.get("HXCPP_XLINUX64_STRIP");
            if (hxcpp_xlinux64_strip == null) hxcpp_xlinux64_strip = '$dkp/devkitA64/bin/aarch64-none-elf-strip';
            
            var hxcpp_xlinux64_ranlib = project.defines.get("HXCPP_XLINUX64_RANLIB");
            if (hxcpp_xlinux64_ranlib == null) hxcpp_xlinux64_ranlib = '$dkp/devkitA64/bin/aarch64-none-elf-ranlib';
            
            var hxcpp_xlinux64_ar = project.defines.get("HXCPP_XLINUX64_AR");
            if (hxcpp_xlinux64_ar == null) hxcpp_xlinux64_ar = '$dkp/devkitA64/bin/aarch64-none-elf-ar';
            
            flags.push('-DHXCPP_XLINUX64_CXX=$hxcpp_xlinux64_cxx');
            flags.push('-DHXCPP_XLINUX64_STRIP=$hxcpp_xlinux64_strip');
            flags.push('-DHXCPP_XLINUX64_RANLIB=$hxcpp_xlinux64_ranlib');
            flags.push('-DHXCPP_XLINUX64_AR=$hxcpp_xlinux64_ar');

            System.runCommand("", "haxe", haxeArgs);

            if (noOutput) return;

            CPPHelper.compile(project, targetDirectory + "/obj", flags);
            
            var libName = project.debug ? "libApplicationMain-debug.a" : "libApplicationMain.a";
            var staticLib = targetDirectory + "/obj/" + libName;
            Log.info("Static library created: " + staticLib);
            
            var limePath = getLimePath();
            var path = Path.combine(limePath, "templates/switch/MakeFileNRO");
            
            if (!FileSystem.exists(path)) {
                Log.error("Could not find Makefile template at: " + path);
                return;
            }

            var makefileTemplate = File.getContent(path);

            var additionalLibs = [];
            var libsStr = project.config.getString("switch.libs");
            if (libsStr == null || libsStr == "") libsStr = "";
            additionalLibs = libsStr.split(",").map(s -> s.trim());

            SwitchLinker.finalBuild({
                switchExportPath: targetDirectory,
                projectName: project.app.file,
                projectTitle: project.meta.title,
                projectAuthor: project.meta.company,
                projectVersion: project.meta.version,
                mainLibPath: staticLib,
                romfsPath: Path.combine(applicationDirectory, "SWITCH_ASSETS/romfs"),
                outputDir: "bin",
                limePath: limePath,
                makeFileTemplate: makefileTemplate,
                maxJobs: 4,
                additionalLibs: additionalLibs
            });
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
        DeploymentHelper.deploy(project, targetFlags, targetDirectory, "Nintendo Switch");
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
        var context = project.templateContext;
        context.CPP_DIR = targetDirectory + "/obj/";
        context.BUILD_DIR = project.app.path + "/switch";
        return context;
    }

    private function getDisplayHXML():HXML
    {
        var path = targetDirectory + "/haxe/" + buildType + ".hxml";

        if (FileSystem.exists(path))
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
        var dkp = Sys.getEnv("DEVKITPRO");
        var commands = [];

        commands.push([
            "-Dnx=1",
            "-DHX_NX=1",
            "-Dstatic",
            "-Dstatic_link",
            "-DBINDIR=Switch",
            "-DHXCPP_ARM64",
            "-DDEVKITPRO=" + dkp,
            "-DCXX=" + dkp + "/devkitA64/bin/aarch64-none-elf-g++",
            "-DHXCPP_STRIP=" + dkp + "/devkitA64/bin/aarch64-none-elf-strip",
            "-DHXCPP_AR=" + dkp + "/devkitA64/bin/aarch64-none-elf-ar",
            "-DHXCPP_RANLIB=" + dkp + "/devkitA64/bin/aarch64-none-elf-ranlib"
        ]);

        CPPHelper.rebuild(project, commands);
    }

    public override function run():Void
    {
        var nroPath = Path.combine(applicationDirectory, project.app.file + ".nro");
        
        var consoleIP = project.config.getString("switch.ip");
        if (targetFlags.exists("ip")) consoleIP = targetFlags.get("ip");

        if (consoleIP == null || consoleIP == "") {
            Log.warn("Console IP not found, letting nxlink decide");
        }

        if (!FileSystem.exists(nroPath)) {
            Log.error("NRO file not found at: " + nroPath);
            return;
        }

        var stat = FileSystem.stat(nroPath);
        var fileSizeMB:Float = Math.round((stat.size / 1024.0 / 1024.0) * 100) / 100;
        final finalIP:String = consoleIP == null || consoleIP == "" ? "to console" : consoleIP;

        Log.info("Sending: [" + project.app.file + ".nro] (" + fileSizeMB + " MB) to " + finalIP);

        var dkp = Sys.getEnv("DEVKITPRO");
        if (dkp == null || dkp == "") {
            Log.error("DEVKITPRO environment variable not found");
            return;
        }

        var nxlinkProgram = Path.combine(dkp, "tools/bin/nxlink");
        if (System.hostPlatform == WINDOWS) nxlinkProgram += ".exe";

        if (!FileSystem.exists(nxlinkProgram)) {
            Log.error("nxlink program not found at: " + nxlinkProgram + " (Maybe switch-tools on DevkitPro is not installed?)");
            return;
        }

        var arguments = ["-a", consoleIP, nroPath];

        // No set IP if empty, Let Nxlink find the console
        if (consoleIP == null || consoleIP == "") {
            arguments = ["-s", nroPath];
        }
        else
            arguments.push("-s");

        var exitCode = System.runCommand("", nxlinkProgram, arguments);        
        if (exitCode != 0) {
            Log.error("nxlink: Transfer failed with code " + exitCode);
        }
    }

    public override function update():Void
    {
        AssetHelper.processLibraries(project, targetDirectory);

        var context = generateContext();
        context.OUTPUT_DIR = targetDirectory;

        System.mkdir(targetDirectory);
        System.mkdir(targetDirectory + "/obj");
        System.mkdir(targetDirectory + "/haxe");
        System.mkdir(applicationDirectory);
        
        var limePath = getLimePath();

        var limeLibDest = Path.combine(targetDirectory, "obj/LIME_LIB/lib");
        System.mkdir(limeLibDest);

        var limeSource = Path.combine(limePath, "ndll/Switch/liblime.a");
        if (FileSystem.exists(limeSource)) {
            File.copy(limeSource, Path.combine(limeLibDest, "liblime.a"));
        }

        var romfsDirectory = Path.combine(applicationDirectory, "SWITCH_ASSETS/romfs");
        System.mkdir(romfsDirectory);

        var icons = project.icons;

        if (icons.length == 0) {
            var defaultIconPath = System.findTemplate(project.templatePaths, "default/icon.svg");
            if (defaultIconPath != null) {
                Log.info("Using default icon for Switch: " + defaultIconPath);
                
                var switchAssetsDir = Path.combine(applicationDirectory, "SWITCH_ASSETS");
                System.mkdir(switchAssetsDir);
                
                var iconPngPath = Path.combine(switchAssetsDir, "icon_temp.png");
                var iconJpgPath = Path.combine(switchAssetsDir, "icon.jpg");
                
                if (IconHelper.createIcon([new Icon(defaultIconPath)], 256, 256, iconPngPath)) {
                    try {
                        var image = Image.fromFile(iconPngPath);
                        
                        if (image != null) {
                            if (image.width != 256 || image.height != 256) {
                                Log.info("Resizing default icon to 256x256...");
                                image.resize(256, 256);
                            }
                            
                            var jpegBytes = image.encode(ImageFileFormat.JPEG, 100);
                            
                            if (jpegBytes != null) {
                                File.saveBytes(iconJpgPath, jpegBytes);
                                Log.info("Switch icon created from default at: " + iconJpgPath + " (256x256)");
                                context.HAS_ICON = true;
                            } else {
                                Log.warn("Could not encode default icon to JPEG format");
                            }
                        } else {
                            Log.warn("Could not load default icon PNG for conversion");
                        }
                    } catch (e:Dynamic) {
                        Log.warn("Error converting default icon to JPG: " + e);
                    }
                    
                    if (FileSystem.exists(iconPngPath)) {
                        FileSystem.deleteFile(iconPngPath);
                    }
                } else {
                    Log.warn("Could not create Switch icon from default");
                }
            }
        }

        if (icons.length > 0) {
            var switchAssetsDir = Path.combine(applicationDirectory, "SWITCH_ASSETS");
            System.mkdir(switchAssetsDir);

            var iconPngPath = Path.combine(switchAssetsDir, "icon_temp.png");
            var iconJpgPath = Path.combine(switchAssetsDir, "icon.jpg");
            
            if (IconHelper.createIcon(icons, 256, 256, iconPngPath)) {
                try {
                    var image = Image.fromFile(iconPngPath);
                    
                    if (image != null) {
                        if (image.width != 256 || image.height != 256) {
                            Log.info("Resizing icon to 256x256...");
                            image.resize(256, 256);
                        }
                        
                        var jpegBytes = image.encode(ImageFileFormat.JPEG, 100);
                        
                        if (jpegBytes != null) {
                            File.saveBytes(iconJpgPath, jpegBytes);
                            Log.info("Switch icon created at: " + iconJpgPath + " (256x256)");
                            context.HAS_ICON = true;
                        } else {
                            Log.error("Could not encode image to JPEG format");
                        }
                    } else {
                        Log.error("Could not load PNG image for conversion");
                    }
                } catch (e:Dynamic) {
                    Log.error("Error converting icon to JPG: " + e);
                }
                
                if (FileSystem.exists(iconPngPath)) {
                    FileSystem.deleteFile(iconPngPath);
                }
            } else {
                Log.error("Could not create Switch icon");
            }
        }

        ProjectHelper.recursiveSmartCopyTemplate(project, "haxe", targetDirectory + "/haxe", context);
        ProjectHelper.recursiveSmartCopyTemplate(project, targetType + "/hxml", targetDirectory + "/haxe", context);

        if (targetType == "cpp")
        {
            ProjectHelper.recursiveSmartCopyTemplate(project, "cpp/static", targetDirectory + "/obj", context);
        }

        for (asset in project.assets)
        {
            var path = Path.combine(romfsDirectory, asset.targetPath);
            if (asset.embed != true)
            {
                System.mkdir(Path.directory(path));
                if (asset.type != AssetType.TEMPLATE)
                    AssetHelper.copyAssetIfNewer(asset, path);
                else
                    AssetHelper.copyAsset(asset, path, context);
            }
        }
    }

    public override function watch():Void
    {
        var hxml = getDisplayHXML();
        var dirs = hxml.getClassPaths(true);
        var command = ProjectHelper.getCurrentCommand();
        System.watch(command, dirs);
    }

    @ignore public override function install():Void {}
    @ignore public override function trace():Void {}
    @ignore public override function uninstall():Void {}
}