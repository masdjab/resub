# Resub
Movie Subtitle Adjuster

## What is Resub?
Resub is a tool to adjust subtitle text timing based on a config file in JSON format.

## How to Use
`ruby resub.rb ori_subtitle_file new_subtitle_file correction_file`
where:
- `ori_subtitle_file` is the original subtitle file name (.srt)
- `new_subtitle_file` is the output file name (.srt)
- `correction_file` is an adjustment config file name (.json)

Example:
`ruby resub.rb "The Movie - Original.srt" "The Movie.srt" "The Movie.json"`

You can type `ruby resub.rb` to display the usage instruction.


## Adjustment Config File Format
The config file format is a JSON file.

Example:
```
{
  "corrections": [
    {
      "actual": "00:00:42,755", 
      "expected": "00:00:30"
    }, 
    {
      "actual": "00:01:00,066", 
      "expected": "00:00:45"
    }, 
    {
      "actual": "00:50:40,085", 
      "expected": "00:45:37"
    }, 
    {
      "actual": "01:46:13,456", 
      "expected": "01:33:03"
    }
  ]
}
```
