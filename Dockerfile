# Use Nginx as the base image
FROM nginx:alpine

# Copy all application files to the Nginx html directory
COPY index.html /usr/share/nginx/html/
COPY index.js /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/
COPY images/ /usr/share/nginx/html/images/
COPY sounds/ /usr/share/nginx/html/sounds/

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
