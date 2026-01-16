package lime.tools.haxenxcompiler;

import hxp.System;
import hxp.Path;
import hxp.Log;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * Args for the MakeFile
 */
typedef SwitchMakeFileArgs = {
    var switchExportPath:String;
    var projectName:String;
    var projectTitle:String;
    var projectAuthor:String;
    var projectVersion:String;
    var mainLibPath:String;
    var romfsPath:String;
    var outputDir:String;
    var limePath:String;
    var makeFileTemplate:String;
    var maxJobs:Int;
}

/**
 * Linker for the Switch, for generating the executables for the console
 * 
 * Based on:
 * https://github.com/Slushi-Github/HaxeNXCompiler/blob/main/source/compilers/nx/NXLinker.hx
 * 
 * @author Slushi
 */
class SwitchLinker {
	
	/**
	 * Generates the MakeFile and executes it
	 * @param args The arguments for the MakeFile
	 */
    public static function finalBuild(args:SwitchMakeFileArgs):Void {
        var basePath = Sys.getCwd().replace("\\", "/");
        
        var exportPath = args.switchExportPath;
        if (Path.isRelative(exportPath)) {
            exportPath = Path.combine(basePath, exportPath);
        }
        
        var objDir = Path.combine(exportPath, "obj");
        var binDir = Path.combine(exportPath, "bin");
        
        if (!FileSystem.exists(objDir)) FileSystem.createDirectory(objDir);
        if (!FileSystem.exists(binDir)) FileSystem.createDirectory(binDir);
        
        args.switchExportPath = exportPath;
        
        createMakefile(args);
        compileMakefile(args);
    }
    
	/**
	 * Creates the MakeFile
	 * @param args The arguments for the MakeFile
	 */
    private static function createMakefile(args:SwitchMakeFileArgs):Void {
        var makeFile = args.makeFileTemplate;
        var exportPath = args.switchExportPath;

        makeFile = makeFile.replace("[LIME_PROJECT_FILENAME]", args.projectName);
        makeFile = makeFile.replace("[LIME_PROJECT_TITLE]", args.projectTitle);
        makeFile = makeFile.replace("[LIME_PROJECT_AUTHOR]", args.projectAuthor);
        makeFile = makeFile.replace("[LIME_PROJECT_VERSION]", args.projectVersion);
        makeFile = makeFile.replace("[LIME_MAIN_SRC_DIR]", "../obj");
        
        var libFileName = Path.withoutDirectory(args.mainLibPath);
        makeFile = makeFile.replace("[HAXE_MAIN_LIB]", Path.combine(exportPath, "obj/" + libFileName));
        
        makeFile = makeFile.replace("[LIME_MAIN_DIR]", Path.combine(exportPath, "obj/LIME_LIB"));
        
        var absoluteOutDir = Path.combine(exportPath, "bin");
        makeFile = makeFile.replace("[OUT_DIR]", absoluteOutDir);
        
        var assetsPath = Path.combine(exportPath, "bin/SWITCH_ASSETS");
        makeFile = makeFile.replace("[SWITCH_ASSETS_DIR]", assetsPath);
        makeFile = makeFile.replace("[LIME_APPLICATION_DIR]", Path.combine(assetsPath, "romfs"));
        
        var makefilePath = Path.combine(exportPath, "obj/Makefile");
        File.saveContent(makefilePath, makeFile);
    }
    
	/**
	 * Compiles the MakeFile
	 * @param args The arguments for the MakeFile
	 */
    private static function compileMakefile(args:SwitchMakeFileArgs):Void {
        var objDir = Path.combine(args.switchExportPath, "obj");
        var originalDir = Sys.getCwd();
        
        Sys.setCwd(objDir);
        var compileResult = System.runCommand("", "make", ["-j" + args.maxJobs]);
        Sys.setCwd(originalDir);
        
        if (compileResult != 0) {
            Log.error("Nintendo Switch compilation failed!");
        }
    }
}