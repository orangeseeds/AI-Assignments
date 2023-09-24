# zig build-obj -target wasm32-freestanding test.zig && zig clang -target wasm32-freestanding -Wl,--allow-undefined -Wl,--export-all -Wl,--export-table -Wl,--no-entry -nostdlib test.o -o test.wasm
build: 
	zig build-lib ./src/wasm.zig -target wasm32-freestanding -dynamic -rdynamic -O ReleaseSmall
	mv wasm.wasm ./ui/wasm
	mv wasm.wasm.o ./ui/wasm

serve:
	python -m http.server -d ./ui/
