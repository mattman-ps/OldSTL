# Deploying OldSTL - Free Hosting Options

This guide covers several free hosting options for deploying your OldSTL historical map application.

## Prerequisites

- A GitHub account
- Git installed on your computer
- Your OldSTL project files

---

## Option 1: GitHub Pages (Recommended)

GitHub Pages is perfect for static sites like OldSTL. It's free, fast, and easy to set up.

### Step 1: Create a GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click the **+** icon in the top-right corner
3. Select **New repository**
4. Name it `oldstl` (or any name you prefer)
5. Make it **Public**
6. Click **Create repository**

### Step 2: Push Your Code to GitHub

Open PowerShell in your project directory and run:

```powershell
# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit your files
git commit -m "Initial commit - OldSTL historical map"

# Add your GitHub repository as remote (replace USERNAME with your GitHub username)
git remote add origin https://github.com/USERNAME/oldstl.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 3: Enable GitHub Pages

1. Go to your repository on GitHub
2. Click **Settings** (top menu)
3. Click **Pages** (left sidebar)
4. Under **Source**, select **main** branch
5. Click **Save**
6. Wait 1-2 minutes for deployment

### Step 4: Access Your Site

Your site will be live at:
```
https://USERNAME.github.io/oldstl/
```

### Updating Your Site

After making changes:

```powershell
git add .
git commit -m "Description of changes"
git push
```

GitHub Pages will automatically update within 1-2 minutes.

---

## Option 2: Netlify

Netlify offers excellent performance and automatic deployments.

### Method A: Deploy via Git

1. Go to [Netlify](https://www.netlify.com/)
2. Sign up/Sign in (can use GitHub account)
3. Click **Add new site** → **Import an existing project**
4. Choose **GitHub** and authorize Netlify
5. Select your `oldstl` repository
6. Click **Deploy site**

Your site will be live at a random URL like: `https://random-name-123456.netlify.app`

### Method B: Drag and Drop

1. Go to [Netlify](https://app.netlify.com/drop)
2. Drag your entire project folder onto the upload area
3. Wait for deployment to complete

### Custom Domain (Optional)

1. Click **Domain settings** in Netlify dashboard
2. Click **Add custom domain**
3. Follow instructions to configure DNS

---

## Option 3: Vercel

Vercel is optimized for modern web projects.

### Steps

1. Go to [Vercel](https://vercel.com/)
2. Sign up/Sign in with GitHub
3. Click **Add New** → **Project**
4. Import your `oldstl` repository
5. Click **Deploy**

Your site will be live at: `https://oldstl.vercel.app` (or similar)

### Update Your Site

Push changes to GitHub - Vercel auto-deploys:

```powershell
git add .
git commit -m "Update photos"
git push
```

---

## Option 4: Cloudflare Pages

Fast global CDN with unlimited bandwidth.

### Steps

1. Go to [Cloudflare Pages](https://pages.cloudflare.com/)
2. Sign up/Sign in
3. Click **Create a project**
4. Connect your GitHub account
5. Select your `oldstl` repository
6. Build settings:
   - **Build command**: (leave empty)
   - **Build output directory**: `/`
7. Click **Save and Deploy**

---

## Option 5: Render

Simple and straightforward static site hosting.

### Steps

1. Go to [Render](https://render.com/)
2. Sign up/Sign in with GitHub
3. Click **New** → **Static Site**
4. Connect your repository
5. Settings:
   - **Build Command**: (leave empty)
   - **Publish Directory**: `.`
6. Click **Create Static Site**

---

## Comparison Table

| Provider | Custom Domain | SSL/HTTPS | Auto Deploy | Bandwidth | Speed |
|----------|--------------|-----------|-------------|-----------|-------|
| GitHub Pages | ✅ Free | ✅ Yes | ✅ Yes | ✅ Unlimited | ⭐⭐⭐ |
| Netlify | ✅ Free | ✅ Yes | ✅ Yes | 100GB/mo | ⭐⭐⭐⭐⭐ |
| Vercel | ✅ Free | ✅ Yes | ✅ Yes | 100GB/mo | ⭐⭐⭐⭐⭐ |
| Cloudflare | ✅ Free | ✅ Yes | ✅ Yes | ✅ Unlimited | ⭐⭐⭐⭐⭐ |
| Render | ✅ Free | ✅ Yes | ✅ Yes | 100GB/mo | ⭐⭐⭐⭐ |

---

## Important Notes

### CORS Issues with JSON

All these platforms serve static files correctly. Your `StlLocations.json` will work without CORS issues.

### HTTPS

All platforms automatically provide free SSL certificates (HTTPS), which is important for:

- Security
- SEO
- Modern browser features
- Geolocation APIs (if you add them later)

### Custom Domain Setup

If you want to use your own domain (e.g., `oldstl.com`):

1. Purchase a domain from Namecheap, Google Domains, etc.
2. In your hosting platform, add the custom domain
3. Update your domain's DNS records (provided by the platform)
4. Wait 24-48 hours for DNS propagation

---

## Recommended Workflow

**Best Practice: GitHub Pages or Netlify**

1. **Develop locally** using Live Server in VS Code
2. **Test thoroughly** with different browsers
3. **Commit changes** to Git with descriptive messages
4. **Push to GitHub** - your site updates automatically
5. **Monitor** deployment status in your hosting dashboard

---

## Troubleshooting

### Site Not Loading

- Wait 2-5 minutes after first deployment
- Check deployment logs in your hosting dashboard
- Verify all files are committed to GitHub
- Clear browser cache

### Images Not Showing

- Check image URLs in `StlLocations.json`
- Use absolute URLs for external images
- Verify file paths are correct (case-sensitive on servers)

### Map Not Displaying

- Open browser console (F12) to check for errors
- Verify Leaflet CDN links are working
- Check that `app.js` is loading correctly

---

## Next Steps

After deployment:

1. ✅ Test on mobile devices
2. ✅ Share your site URL
3. ✅ Add Google Analytics (optional)
4. ✅ Submit to search engines
5. ✅ Consider adding a custom domain
6. ✅ Replace placeholder images with real historical photos

---

## Support

- **GitHub Pages**: [Documentation](https://docs.github.com/en/pages)
- **Netlify**: [Documentation](https://docs.netlify.com/)
- **Vercel**: [Documentation](https://vercel.com/docs)
- **Cloudflare Pages**: [Documentation](https://developers.cloudflare.com/pages/)
- **Render**: [Documentation](https://render.com/docs/static-sites)

---
