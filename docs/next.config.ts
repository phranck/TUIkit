import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  images: {
    unoptimized: true,
  },
  env: {
    TUIKIT_VERSION: process.env.TUIKIT_VERSION ?? "0.1.0",
  },
};

export default nextConfig;
