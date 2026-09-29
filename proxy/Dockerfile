FROM nginx:alpine

# Copia a configuração do proxy reverso
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copia a landing page / hub da agência
COPY html/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
