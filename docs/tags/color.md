# Color (same as colour)

> Back to [tags](./)

Sets child element text colors.  One of the two attributes is required, but not both.

| Attributes | Required | Default | Value                    |
|------------|----------|---------|--------------------------|
| text       | False    |         | [Color](https://tweaked.cc/module/colors.html) as string       |
| background | False    |         | [Color](https://tweaked.cc/module/colors.html) as string       |

## Example

```xml
<ccml>
  <body>
    <color text="purple"><text>Purple text!</text></color>
    <colour background="blue"><text>Blue background!</text></colour>
  </body>
</ccml>
```
