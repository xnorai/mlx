def make_metal_preamble_kernel_rules(kernel_specs):
    generated_targets = []
    for name, spec in kernel_specs.items():
        deps = spec.get("deps", [])
        native.genrule(
            name = name,
            srcs = [spec["src"]] + deps,
            outs = ["mlx/backend/metal/jit/{}.cpp".format(name)],
            cmd = """
                bash \
                $(location mlx/backend/metal/make_compiled_preamble.sh) \
                $$(dirname $(location mlx/backend/metal/jit/{name}.cpp)) \
                $(CC) \
            $$(pwd) \
                {name} \
                "-DMLX_METAL_VERSION=320"
            """.format(
                name = name
            ),
            tags = ["manual"],
            tools = ["mlx/backend/metal/make_compiled_preamble.sh"],
            toolchains = ["@bazel_tools//tools/cpp:current_cc_toolchain"],
        )
        generated_targets.append(":" + name)

    native.cc_library(
        name = "preamble_metal",
        # TODO: Unsure if this is necessary, consider removing.
        hdrs = [
            "mlx/backend/metal/jit/includes.h",
            "mlx/backend/metal/kernels.h",
        ],
        srcs = generated_targets,
    )
