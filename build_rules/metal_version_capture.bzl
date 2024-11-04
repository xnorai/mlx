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