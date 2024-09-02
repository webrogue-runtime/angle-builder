original_deps_lines = open("angle/DEPS").readlines()

filtered_deps = []

first_level_markers = [
    "  'third_party/catapult': {\n",
    "  'third_party/dawn': {\n",
    "  'third_party/llvm/src': {\n",
    "  'third_party/SwiftShader': {\n",
    "  'third_party/VK-GL-CTS/src': {\n",
    "  'third_party/rust': {\n",
    "    'name': 'rust',\n",
]

prev_comment_markers = [
    "    'name': 'rust',\n",
]

first_level_filtered = False

for line in original_deps_lines:
    if line in first_level_markers:
        filtered_deps.append("# Filtered by angle-builder\n")
        first_level_filtered = True
    if line in prev_comment_markers:
        filtered_deps[-2] = "# " + filtered_deps[-2]
    if first_level_filtered:
        filtered_deps.append("# " + line)
    else:
        filtered_deps.append(line)
    if line == "  },\n":
        first_level_filtered = False

open("angle/DEPS", "w").writelines(filtered_deps)
