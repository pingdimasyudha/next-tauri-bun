import { defineConfig } from "bumpp";
import tauri from "tauri-version";

export default defineConfig({
  all: true,
  execute: tauri({
    lock: true,
  }),
});