import type { NextConfig } from "next";

type OutputType = "standalone" | "export";

const nextConfig: NextConfig = {
  output: (process.env.NEXT_OUTPUT as OutputType) ?? "standalone",
  distDir: "build",
  images: {
    unoptimized: true,
  },
  assetPrefix: process.env.NEXT_HOST ?? "http://localhost:3000",
};

export default nextConfig;
