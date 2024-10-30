def make_kernel_rules(kernel_specs):
    """Creates genrules for multiple kernel files at once.

    Args:
        kernel_specs: Dict mapping kernel names to their source and dependencies.
        Example:
        {
            "utils": {
                "src": "kernels/utils.h",
                "deps": ["kernels/bf16.h", "kernels/complex.h"]
            },
            "binary_ops": {
                "src": "kernels/binary_ops.h",
                "deps": []
            }
        }
    """
    generated_targets = []
    for name, spec in kernel_specs.items():
        deps = spec.get("deps", [])
        native.genrule(
            name=name,
            srcs=[spec["src"]]
            + deps
            + ["@//mlx/backend/metal:make_compiled_preamble_script"],
            outs=["jit/{}.cpp".format(name)],
            cmd="""
                $(location @//mlx/backend/metal:make_compiled_preamble_script) \
                $$(dirname $(location jit/{name}.cpp)) \
                $(CC) \
                $$(pwd) \
                {src_file} \
                "-DMLX_METAL_VERSION=1"
            """.format(
                name=name,
                src_file=spec["src"].replace("kernels/", "").replace(".h", ""),
            ),
            toolchains=["@bazel_tools//tools/cpp:current_cc_toolchain"],
        )
        generated_targets.append(":" + name)

    native.filegroup(
        name="metal_kernel_sources",
        srcs=generated_targets,
    )
