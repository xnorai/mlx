def _metal_version_repo_impl(ctx):
    versions = {}

    for sdk in ["iphonesimulator", "iphoneos", "macosx"]:
        result = ctx.execute([
            "bash",
            "-c",
            "xcrun -sdk {} metal -v 2>&1 | grep 'Apple metal version' | cut -d' ' -f4 | cut -d'.' -f1 | cut -c1-3 || echo 'undefined'".format(sdk)
        ])

        if result.return_code != 0:
            versions[sdk] = "undefined"
        else:
            version = result.stdout.strip()
            versions[sdk] = version if version else "undefined"

    ctx.file("metal_version.bzl", content = """
METAL_VERSION_IOS_SIMULATOR = "{}"
METAL_VERSION_IOS = "{}"
METAL_VERSION_MACOS = "{}"
""".format(
        versions["iphonesimulator"],
        versions["iphoneos"],
        versions["macosx"]
    ))

    ctx.file("BUILD.bazel", content = """
exports_files(["metal_version.bzl"])
""")

metal_version_repo = repository_rule(
    implementation = _metal_version_repo_impl,
    attrs = {
        "versions": attr.string_dict(),
    }
)

metal_version = module_extension(
    implementation = lambda _: metal_version_repo(name = "metal_version"),
)

