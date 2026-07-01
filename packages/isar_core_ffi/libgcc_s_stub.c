// Enhanced stub for libgcc_s on OpenHarmony
// Provides minimal implementations of required symbols so Rust/FFI libraries can load.
//
// NOTE: This is a compatibility shim. It is NOT a full unwind/TLS implementation.

#include <stdlib.h>
#include <string.h>

// -----------------------------
// Unwind symbols (minimal stubs)
// -----------------------------

void* _Unwind_GetLanguageSpecificData(void* context) { (void)context; return 0; }
void  _Unwind_Resume(void* exception_object) { (void)exception_object; }

// Correct return type is an unwind reason code (int). We just return 0.
int __gcc_personality_v0(int version, int actions,
                         unsigned long exceptionClass,
                         void* exceptionObject,
                         void* context) {
    (void)version; (void)actions; (void)exceptionClass; (void)exceptionObject; (void)context;
    return 0;
}

int   _Unwind_RaiseException(void* exception_object) { (void)exception_object; return 0; }
void* _Unwind_GetRegionStart(void* context) { (void)context; return 0; }
void* _Unwind_GetDataRelBase(void* context) { (void)context; return 0; }
void* _Unwind_GetTextRelBase(void* context) { (void)context; return 0; }

unsigned long _Unwind_GetIP(void* context) { (void)context; return 0; }
unsigned long _Unwind_GetIPInfo(void* context, int* ipBefore) {
    (void)context;
    if (ipBefore) { *ipBefore = 0; }
    return 0;
}
void _Unwind_SetIP(void* context, unsigned long value) { (void)context; (void)value; }

unsigned long _Unwind_GetCFA(void* context) { (void)context; return 0; }
void* _Unwind_GetGR(void* context, int index) { (void)context; (void)index; return 0; }
void  _Unwind_SetGR(void* context, int index, void* value) { (void)context; (void)index; (void)value; }

int _Unwind_Backtrace(void (*callback)(void* context, void* arg), void* arg) {
    (void)callback; (void)arg;
    return 0;
}

// -----------------------------
// Emulated TLS symbol (stub)
// -----------------------------

// This layout matches compiler-rt's __emutls_control for common toolchains.
typedef struct {
    size_t size;
    size_t align;
    void* value;
    void* ptr;
} __emutls_control;

void* __emutls_get_address(void* emutls) {
    __emutls_control* c = (__emutls_control*)emutls;
    if (!c) return 0;
    if (!c->ptr) {
        size_t sz = c->size ? c->size : 1024;
        c->ptr = calloc(1, sz);
        if (c->ptr && c->value) {
            // Best-effort initialize.
            memcpy(c->ptr, c->value, sz);
        }
    }
    return c->ptr;
}
