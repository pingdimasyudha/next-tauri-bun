import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  distDir: "build",
  images: {
    unoptimized: true,
  },
  assetPrefix: process.env.NEXT_HOST ?? "http://localhost:3000",
};

export default nextConfig;
