#!/usr/bin/env python3
"""Generate a traditional Xcode 15 pbxproj for the SakayNa iOS app."""
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path("/Users/princejapor/Projects/SakayNa")
SRC = ROOT / "SakayNa"
PROJ = ROOT / "SakayNa.xcodeproj"
SCHEME_DIR = PROJ / "xcshareddata" / "xcschemes"


def uid(name: str) -> str:
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()


swift_files = sorted(p.relative_to(SRC) for p in SRC.rglob("*.swift"))
groups = {
    "Models": [],
    "Controllers": [],
    "Services": [],
    "Theme": [],
    "Views": [],
    "Screens": [],
    "Components": [],
    "Root": [],
}

for rel in swift_files:
    parts = rel.parts
    if parts[0] == "Models":
        groups["Models"].append(rel)
    elif parts[0] == "Controllers":
        groups["Controllers"].append(rel)
    elif parts[0] == "Services":
        groups["Services"].append(rel)
    elif parts[0] == "Theme":
        groups["Theme"].append(rel)
    elif parts[0] == "Views" and len(parts) == 2:
        groups["Views"].append(rel)
    elif parts[0] == "Views" and parts[1] == "Screens":
        groups["Screens"].append(rel)
    elif parts[0] == "Views" and parts[1] == "Components":
        groups["Components"].append(rel)
    else:
        groups["Root"].append(rel)

project_id = uid("project")
target_id = uid("target")
sources_phase = uid("sources")
resources_phase = uid("resources")
frameworks_phase = uid("frameworks")
root_group = uid("root_group")
products_group = uid("products_group")
src_group = uid("src_group")
product_ref = uid("product_ref")
assets_ref = uid("assets_ref")
assets_build = uid("assets_build")
plist_ref = uid("file:GoogleService-Info.plist")
plist_build = uid("build:GoogleService-Info.plist")
intro_folder_ref = uid("folder:Appintro")
intro_folder_build = uid("build:Appintro")
firebase_package = uid("pkg:firebase-ios-sdk")
firebase_auth_product = uid("prod:FirebaseAuth")
firebase_firestore_product = uid("prod:FirebaseFirestore")
firebase_auth_build = uid("link:FirebaseAuth")
firebase_firestore_build = uid("link:FirebaseFirestore")
proj_cfg_list = uid("proj_cfg_list")
target_cfg_list = uid("target_cfg_list")
proj_debug = uid("proj_debug")
proj_release = uid("proj_release")
target_debug = uid("target_debug")
target_release = uid("target_release")

file_refs = {rel: uid(f"file:{rel}") for rel in swift_files}
build_files = {rel: uid(f"build:{rel}") for rel in swift_files}
group_ids = {
    "Models": uid("group:Models"),
    "Controllers": uid("group:Controllers"),
    "Services": uid("group:Services"),
    "Theme": uid("group:Theme"),
    "Views": uid("group:Views"),
    "Screens": uid("group:Screens"),
    "Components": uid("group:Components"),
}

lines = []
a = lines.append
a("// !$*UTF8*$!")
a("{")
a("\tarchiveVersion = 1;")
a("\tclasses = {")
a("\t};")
a("\tobjectVersion = 56;")
a("\tobjects = {")
a("")

a("/* Begin PBXBuildFile section */")
for rel in swift_files:
    a(f"\t\t{build_files[rel]} /* {rel.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[rel]} /* {rel.name} */; }};")
a(f"\t\t{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};")
a(f"\t\t{plist_build} /* GoogleService-Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {plist_ref} /* GoogleService-Info.plist */; }};")
a(f"\t\t{intro_folder_build} /* Appintro in Resources */ = {{isa = PBXBuildFile; fileRef = {intro_folder_ref} /* Appintro */; }};")
a(f"\t\t{firebase_auth_build} /* FirebaseAuth in Frameworks */ = {{isa = PBXBuildFile; productRef = {firebase_auth_product} /* FirebaseAuth */; }};")
a(f"\t\t{firebase_firestore_build} /* FirebaseFirestore in Frameworks */ = {{isa = PBXBuildFile; productRef = {firebase_firestore_product} /* FirebaseFirestore */; }};")
a("/* End PBXBuildFile section */")
a("")

a("/* Begin PBXFileReference section */")
a(f"\t\t{product_ref} /* SakayNa.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = SakayNa.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
a(f"\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")
a(f"\t\t{plist_ref} /* GoogleService-Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = \"GoogleService-Info.plist\"; sourceTree = \"<group>\"; }};")
a(f"\t\t{intro_folder_ref} /* Appintro */ = {{isa = PBXFileReference; lastKnownFileType = folder; path = Appintro; sourceTree = \"<group>\"; }};")
for rel in swift_files:
    a(f"\t\t{file_refs[rel]} /* {rel.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{rel.name}\"; sourceTree = \"<group>\"; }};")
a("/* End PBXFileReference section */")
a("")

a("/* Begin PBXFrameworksBuildPhase section */")
a(f"\t\t{frameworks_phase} /* Frameworks */ = {{")
a("\t\t\tisa = PBXFrameworksBuildPhase;")
a("\t\t\tbuildActionMask = 2147483647;")
a("\t\t\tfiles = (")
a(f"\t\t\t\t{firebase_auth_build} /* FirebaseAuth in Frameworks */,")
a(f"\t\t\t\t{firebase_firestore_build} /* FirebaseFirestore in Frameworks */,")
a("\t\t\t);")
a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
a("\t\t};")
a("/* End PBXFrameworksBuildPhase section */")
a("")

def children_block(rels):
    return "".join(f"\t\t\t\t{file_refs[rel]} /* {rel.name} */,\n" for rel in rels)

a("/* Begin PBXGroup section */")
a(f"\t\t{root_group} = {{")
a("\t\t\tisa = PBXGroup;")
a("\t\t\tchildren = (")
a(f"\t\t\t\t{src_group} /* SakayNa */,")
a(f"\t\t\t\t{products_group} /* Products */,")
a("\t\t\t);")
a('\t\t\tsourceTree = "<group>";')
a("\t\t};")
a(f"\t\t{products_group} /* Products */ = {{")
a("\t\t\tisa = PBXGroup;")
a("\t\t\tchildren = (")
a(f"\t\t\t\t{product_ref} /* SakayNa.app */,")
a("\t\t\t);")
a("\t\t\tname = Products;")
a('\t\t\tsourceTree = "<group>";')
a("\t\t};")
a(f"\t\t{src_group} /* SakayNa */ = {{")
a("\t\t\tisa = PBXGroup;")
a("\t\t\tchildren = (")
for rel in groups["Root"]:
    a(f"\t\t\t\t{file_refs[rel]} /* {rel.name} */,")
a(f"\t\t\t\t{group_ids['Models']} /* Models */,")
a(f"\t\t\t\t{group_ids['Controllers']} /* Controllers */,")
a(f"\t\t\t\t{group_ids['Services']} /* Services */,")
a(f"\t\t\t\t{group_ids['Views']} /* Views */,")
a(f"\t\t\t\t{group_ids['Theme']} /* Theme */,")
a(f"\t\t\t\t{assets_ref} /* Assets.xcassets */,")
a(f"\t\t\t\t{plist_ref} /* GoogleService-Info.plist */,")
a(f"\t\t\t\t{intro_folder_ref} /* Appintro */,")
a("\t\t\t);")
a("\t\t\tpath = SakayNa;")
a('\t\t\tsourceTree = "<group>";')
a("\t\t};")

for name in ("Models", "Controllers", "Services", "Theme"):
    a(f"\t\t{group_ids[name]} /* {name} */ = {{")
    a("\t\t\tisa = PBXGroup;")
    a("\t\t\tchildren = (")
    a(children_block(groups[name]).rstrip("\n"))
    a("\t\t\t);")
    a(f"\t\t\tpath = {name};")
    a('\t\t\tsourceTree = "<group>";')
    a("\t\t};")

a(f"\t\t{group_ids['Views']} /* Views */ = {{")
a("\t\t\tisa = PBXGroup;")
a("\t\t\tchildren = (")
for rel in groups["Views"]:
    a(f"\t\t\t\t{file_refs[rel]} /* {rel.name} */,")
a(f"\t\t\t\t{group_ids['Screens']} /* Screens */,")
a(f"\t\t\t\t{group_ids['Components']} /* Components */,")
a("\t\t\t);")
a("\t\t\tpath = Views;")
a('\t\t\tsourceTree = "<group>";')
a("\t\t};")

a(f"\t\t{group_ids['Screens']} /* Screens */ = {{")
a("\t\t\tisa = PBXGroup;")
a("\t\t\tchildren = (")
a(children_block(groups["Screens"]).rstrip("\n"))
a("\t\t\t);")
a("\t\t\tpath = Screens;")
a('\t\t\tsourceTree = "<group>";')
a("\t\t};")

a(f"\t\t{group_ids['Components']} /* Components */ = {{")
a("\t\t\tisa = PBXGroup;")
a("\t\t\tchildren = (")
a(children_block(groups["Components"]).rstrip("\n"))
a("\t\t\t);")
a("\t\t\tpath = Components;")
a('\t\t\tsourceTree = "<group>";')
a("\t\t};")
a("/* End PBXGroup section */")
a("")

a("/* Begin PBXNativeTarget section */")
a(f"\t\t{target_id} /* SakayNa */ = {{")
a("\t\t\tisa = PBXNativeTarget;")
a(f"\t\t\tbuildConfigurationList = {target_cfg_list} /* Build configuration list for PBXNativeTarget \"SakayNa\" */;")
a("\t\t\tbuildPhases = (")
a(f"\t\t\t\t{sources_phase} /* Sources */,")
a(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
a(f"\t\t\t\t{resources_phase} /* Resources */,")
a("\t\t\t);")
a("\t\t\tbuildRules = (")
a("\t\t\t);")
a("\t\t\tdependencies = (")
a("\t\t\t);")
a("\t\t\tname = SakayNa;")
a("\t\t\tpackageProductDependencies = (")
a(f"\t\t\t\t{firebase_auth_product} /* FirebaseAuth */,")
a(f"\t\t\t\t{firebase_firestore_product} /* FirebaseFirestore */,")
a("\t\t\t);")
a("\t\t\tproductName = SakayNa;")
a(f"\t\t\tproductReference = {product_ref} /* SakayNa.app */;")
a('\t\t\tproductType = "com.apple.product-type.application";')
a("\t\t};")
a("/* End PBXNativeTarget section */")
a("")

a("/* Begin PBXProject section */")
a(f"\t\t{project_id} /* Project object */ = {{")
a("\t\t\tisa = PBXProject;")
a("\t\t\tattributes = {")
a("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
a('\t\t\t\tLastSwiftUpdateCheck = 1520;')
a("\t\t\t\tLastUpgradeCheck = 1520;")
a("\t\t\t\tTargetAttributes = {")
a(f"\t\t\t\t\t{target_id} = {{")
a("\t\t\t\t\t\tCreatedOnToolsVersion = 15.2;")
a("\t\t\t\t\t};")
a("\t\t\t\t};")
a("\t\t\t};")
a(f"\t\t\tbuildConfigurationList = {proj_cfg_list} /* Build configuration list for PBXProject \"SakayNa\" */;")
a('\t\t\tcompatibilityVersion = "Xcode 14.0";')
a("\t\t\tdevelopmentRegion = en;")
a("\t\t\thasScannedForEncodings = 0;")
a("\t\t\tknownRegions = (")
a("\t\t\t\ten,")
a("\t\t\t\tBase,")
a("\t\t\t);")
a(f"\t\t\tmainGroup = {root_group};")
a("\t\t\tpackageReferences = (")
a(f"\t\t\t\t{firebase_package} /* XCRemoteSwiftPackageReference \"firebase-ios-sdk\" */,")
a("\t\t\t);")
a(f"\t\t\tproductRefGroup = {products_group} /* Products */;")
a('\t\t\tprojectDirPath = "";')
a('\t\t\tprojectRoot = "";')
a("\t\t\ttargets = (")
a(f"\t\t\t\t{target_id} /* SakayNa */,")
a("\t\t\t);")
a("\t\t};")
a("/* End PBXProject section */")
a("")

a("/* Begin PBXResourcesBuildPhase section */")
a(f"\t\t{resources_phase} /* Resources */ = {{")
a("\t\t\tisa = PBXResourcesBuildPhase;")
a("\t\t\tbuildActionMask = 2147483647;")
a("\t\t\tfiles = (")
a(f"\t\t\t\t{assets_build} /* Assets.xcassets in Resources */,")
a(f"\t\t\t\t{plist_build} /* GoogleService-Info.plist in Resources */,")
a(f"\t\t\t\t{intro_folder_build} /* Appintro in Resources */,")
a("\t\t\t);")
a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
a("\t\t};")
a("/* End PBXResourcesBuildPhase section */")
a("")

a("/* Begin PBXSourcesBuildPhase section */")
a(f"\t\t{sources_phase} /* Sources */ = {{")
a("\t\t\tisa = PBXSourcesBuildPhase;")
a("\t\t\tbuildActionMask = 2147483647;")
a("\t\t\tfiles = (")
for rel in swift_files:
    a(f"\t\t\t\t{build_files[rel]} /* {rel.name} in Sources */,")
a("\t\t\t);")
a("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
a("\t\t};")
a("/* End PBXSourcesBuildPhase section */")
a("")

common_proj = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				SDKROOT = iphoneos;
"""

common_target = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = SakayNa;
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.travel";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.sakayna.SakayNa;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
"""

a("/* Begin XCBuildConfiguration section */")
a(f"\t\t{proj_debug} /* Debug */ = {{")
a("\t\t\tisa = XCBuildConfiguration;")
a("\t\t\tbuildSettings = {")
a(common_proj)
a("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
a("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
a("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (")
a('\t\t\t\t\t"DEBUG=1",')
a("\t\t\t\t\t\"$(inherited)\",")
a("\t\t\t\t);")
a("\t\t\t\tMTL_FAST_MATH = YES;")
a("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
a("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
a("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
a("\t\t\t};")
a("\t\t\tname = Debug;")
a("\t\t};")
a(f"\t\t{proj_release} /* Release */ = {{")
a("\t\t\tisa = XCBuildConfiguration;")
a("\t\t\tbuildSettings = {")
a(common_proj.replace("DEBUG_INFORMATION_FORMAT = dwarf;", 'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";').replace("ENABLE_TESTABILITY = YES;", "ENABLE_NS_ASSERTIONS = NO;"))
a("\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;")
a("\t\t\t\tMTL_FAST_MATH = YES;")
a("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
a("\t\t\t\tVALIDATE_PRODUCT = YES;")
a("\t\t\t};")
a("\t\t\tname = Release;")
a("\t\t};")
a(f"\t\t{target_debug} /* Debug */ = {{")
a("\t\t\tisa = XCBuildConfiguration;")
a("\t\t\tbuildSettings = {")
a(common_target)
a("\t\t\t};")
a("\t\t\tname = Debug;")
a("\t\t};")
a(f"\t\t{target_release} /* Release */ = {{")
a("\t\t\tisa = XCBuildConfiguration;")
a("\t\t\tbuildSettings = {")
a(common_target)
a("\t\t\t};")
a("\t\t\tname = Release;")
a("\t\t};")
a("/* End XCBuildConfiguration section */")
a("")

a("/* Begin XCConfigurationList section */")
a(f"\t\t{proj_cfg_list} /* Build configuration list for PBXProject \"SakayNa\" */ = {{")
a("\t\t\tisa = XCConfigurationList;")
a("\t\t\tbuildConfigurations = (")
a(f"\t\t\t\t{proj_debug} /* Debug */,")
a(f"\t\t\t\t{proj_release} /* Release */,")
a("\t\t\t);")
a("\t\t\tdefaultConfigurationIsVisible = 0;")
a("\t\t\tdefaultConfigurationName = Release;")
a("\t\t};")
a(f"\t\t{target_cfg_list} /* Build configuration list for PBXNativeTarget \"SakayNa\" */ = {{")
a("\t\t\tisa = XCConfigurationList;")
a("\t\t\tbuildConfigurations = (")
a(f"\t\t\t\t{target_debug} /* Debug */,")
a(f"\t\t\t\t{target_release} /* Release */,")
a("\t\t\t);")
a("\t\t\tdefaultConfigurationIsVisible = 0;")
a("\t\t\tdefaultConfigurationName = Release;")
a("\t\t};")
a("/* End XCConfigurationList section */")
a("")
a("/* Begin XCRemoteSwiftPackageReference section */")
a(f"\t\t{firebase_package} /* XCRemoteSwiftPackageReference \"firebase-ios-sdk\" */ = {{")
a("\t\t\tisa = XCRemoteSwiftPackageReference;")
a('\t\t\trepositoryURL = "https://github.com/firebase/firebase-ios-sdk";')
a("\t\t\trequirement = {")
a("\t\t\t\tkind = exactVersion;")
a("\t\t\t\tversion = 11.9.0;")
a("\t\t\t};")
a("\t\t};")
a("/* End XCRemoteSwiftPackageReference section */")
a("")
a("/* Begin XCSwiftPackageProductDependency section */")
a(f"\t\t{firebase_auth_product} /* FirebaseAuth */ = {{")
a("\t\t\tisa = XCSwiftPackageProductDependency;")
a(f"\t\t\tpackage = {firebase_package} /* XCRemoteSwiftPackageReference \"firebase-ios-sdk\" */;")
a("\t\t\tproductName = FirebaseAuth;")
a("\t\t};")
a(f"\t\t{firebase_firestore_product} /* FirebaseFirestore */ = {{")
a("\t\t\tisa = XCSwiftPackageProductDependency;")
a(f"\t\t\tpackage = {firebase_package} /* XCRemoteSwiftPackageReference \"firebase-ios-sdk\" */;")
a("\t\t\tproductName = FirebaseFirestore;")
a("\t\t};")
a("/* End XCSwiftPackageProductDependency section */")
a("\t};")
a(f"\trootObject = {project_id} /* Project object */;")
a("}")

PROJ.mkdir(parents=True, exist_ok=True)
(PROJ / "project.pbxproj").write_text("\n".join(lines) + "\n")

SCHEME_DIR.mkdir(parents=True, exist_ok=True)
scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1520"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "SakayNa.app"
               BlueprintName = "SakayNa"
               ReferencedContainer = "container:SakayNa.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "SakayNa.app"
            BlueprintName = "SakayNa"
            ReferencedContainer = "container:SakayNa.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "SakayNa.app"
            BlueprintName = "SakayNa"
            ReferencedContainer = "container:SakayNa.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
(SCHEME_DIR / "SakayNa.xcscheme").write_text(scheme)
print(f"Wrote project with {len(swift_files)} Swift files")
for rel in swift_files:
    print(" ", rel)
