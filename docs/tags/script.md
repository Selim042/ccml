# Script

> Back to [tags](./)

Executes an inline Lua script.  More documentation coming soon.

## Example

```xml
<ccml>
  <body>
    <script>
        local ele = getElementById("title",dom)[1]
        ele.value = "Hello, World!"
    </script>
  </body>
</ccml>
```
