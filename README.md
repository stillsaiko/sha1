# sha1
```
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from sha1 import sha1
func main{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;
    let uint32_ptr = alloc();
    assert [uint32_ptr] = 0x1337;
    local hash = sha1(data_ptr = uint32_ptr, n_bytes = 2);
    %{ print(hex(ids.hash)) %}
    return ();
}
```
```cairo 0.10```
