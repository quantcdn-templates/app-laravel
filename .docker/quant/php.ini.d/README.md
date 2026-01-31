# Custom PHP Configuration

Place any custom `.ini` files here to override PHP settings.

Example file `99-custom.ini`:
```ini
; Increase memory limit
memory_limit = 512M

; Increase upload size
upload_max_filesize = 64M
post_max_size = 64M
```

Files are loaded in alphabetical order. Use numbered prefixes (e.g., `90-`, `99-`) to control loading order.
