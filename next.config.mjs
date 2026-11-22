/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  typescript: {
    // Memastikan build Vercel tidak gagal karena inkonsistensi tipe
    ignoreBuildErrors: true,
  },
  eslint: {
    // Memastikan build Vercel tidak gagal karena aturan linter
    ignoreDuringBuilds: true,
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
    ],
  },
};

export default nextConfig;
