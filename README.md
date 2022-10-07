# sha1
```cairo 0.10```
```
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from sha import sha
func main{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;
    let uint32_ptr = alloc();
    let n_bytes = 2;
    assert uint32_ptr[0] = 0x1337;
    local hash = sha1(uint32_ptr, n_bytes);
    %{ print(hex(ids.hash)) %}
    return ();
}
```
