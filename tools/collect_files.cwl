cwlVersion: v1.0
class: ExpressionTool
inputs:
    dir_name: string
    input_files: File[]
outputs:
    output_dir: Directory
expression: |
    ${
        var lis = [];
        for (var i = 0; i < inputs.input_files.length; ++i) {
            lis.push(inputs.input_files[i]);
        }
        return {"output_dir": {
            "class": "Directory",
            "basename": inputs.dir_name,
            "listing": lis
        } };
    }
requirements:
  - class: InlineJavascriptRequirement