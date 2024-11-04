load("@apple_support//lib:apple_support.bzl", "apple_support")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@rules_cc//cc:defs.bzl", "cc_library")

# While rules_apple has support for Metal compilation, it's so convoluted there
# that it's not clear how to use it unless you're building a full blown app. So
# this is a much simpler replacement.

def _metal_library_impl(ctx):
    # Collect source Metal files
    metal_sources = ctx.files.srcs
    metal_headers = ctx.files.hdrs

    # Output file automatically named after the target
    output = ctx.actions.declare_file(ctx.label.name + ".metallib")

    # Compile command.
    air_files = []
    for src in metal_sources:
        air_file = ctx.actions.declare_file(src.basename + ".air")
        air_files.append(air_file)
        args = ctx.actions.args()

        # Includes will be relative to this.
        workspace_root = ctx.label.workspace_root
        if workspace_root == "":
            workspace_root = "."

        # Note that we allow includes wrt workspace root, as specified in Style.
        args.add_all(["metal", "-Wall", "-Wextra", "-fno-fast-math", "-c", src.path, "-o", air_file.path, "-I", workspace_root])

        # Compile .metal files to .air
        apple_support.run(
            actions = ctx.actions,
            xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
            apple_fragment = ctx.fragments.apple,
            inputs = [src] + metal_headers,
            outputs = [air_file],
            executable = "/usr/bin/xcrun",
            arguments = [args],
            mnemonic = "MetalCompile",
        )

    # Link command.
    args = ctx.actions.args()
    args.add_all(["metallib", "-o", output.path])
    args.add_all(air_files)

    apple_support.run(
        actions = ctx.actions,
        xcode_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
        apple_fragment = ctx.fragments.apple,
        inputs = air_files,
        outputs = [output],
        executable = "/usr/bin/xcrun",
        arguments = [args],
        mnemonic = "MetallibCompile",
    )

metal_library = rule(
    implementation = _metal_library_impl,
    fragments = ["apple"],
    attrs = dicts.add(
        apple_support.action_required_attrs(),
        {
            "srcs": attr.label_list(allow_files = [".metal"]),
            "hdrs": attr.label_list(allow_files = [".h"]),
        },
    ),
    outputs = {"out": "%{name}.metallib"},
)

def _metal_version_capture_impl(repository_ctx):
    # Execute the command to get the metal version
    result = repository_ctx.execute(
        ["zsh", "-c", "echo '__METAL_VERSION__' | xcrun -sdk macosx metal -E -x metal -P - | tail -1 | tr -d '\\n'"],
    )

    # Check if the command was successful
    if result.return_code != 0:
        fail("Failed to execute command for metal version: " + result.stderr)

    # Capture the output as the metal version
    metal_version = result.stdout.strip()

    # Write as global var.
    repository_ctx.file("BUILD")
    repository_ctx.file("metal_version.bzl", 'MLX_METAL_VERSION = "{}"'.format(metal_version))

metal_version_capture = repository_rule(
    implementation = _metal_version_capture_impl,
)