# dart-boiler.nvim

dart-boiler.nvim makes Dart class boilerplate a breeze with instant, in-line code generation.

<div align="center">
    
<img height="500" src="https://user-images.githubusercontent.com/7101404/231917203-45afcf2b-4845-4798-a6f0-c38f9edf99ae.gif">
    
</div>
    
<BR>
    
## Why does this exist?

During a rather grueling codebase migration to Dart sound-null-safety, 
I found myself manually generating general class boilerplate and boilerplate for packages like [equatable][] and [json_serializable][].

Note: I was unfortunately unable to use code generation solutions like [freezed][] due to certain limitations.

[equatable]: https://pub.dev/packages/equatable
[json_serializable]: https://pub.dev/packages/json_serializable
[freezed]: https://pub.dev/packages/freezed

<BR>

## Installation

Install like any other vim plugin.
Here are examples using some popular package managers:

<details>
<summary>packer.nvim</summary>

```lua
use 'rafaelcolladojr/dart-boiler.nvim'
```
</details>

<details>
<summary>lazy.nvim</summary>

```lua
{
    'rafaelcolladojr/dart-boiler.nvim'
}
```
</details>

<details>
<summary>vim-plug</summary>
### vim-plug 

```lua
Plug 'rafaelcolladojr/dart-boiler.nvim'
```
</details>

<BR>

## Usage

To generate a field-related boilerplate for a class, first create a class with its fields expressed in the following format:

```dart
class MyClass extends Equatable {
    String! id;
    String! name;
    DateTime dob;
    String? email;
    bool enabled;
}
```

<BR>

Notice the bang(!) after the first two field datatypes.
The symbol following a datatype indicates the nature and scope of that field:

| Symbol | Nature |
| --- | --- |
| ! | Inhereted field |
| ? | Nullable field |
| none | Non-nullable (required) |


<BR>

Select the fields you've created with a visual block selection, and execute the following command:

```vimscript
:lua require('dart-boiler').boil()
```

## Goals

While intended as a quick-fix for a rather specific scenario, this plugin can grow into something more generally applicable.

Here are some features that might help with that:

- [ ] Use Telescope utils for smarter class/field parsing
- [ ] Support generic field types (eg. List<T>)
- [ ] Support default values
