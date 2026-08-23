FROM golang:1.24-alpine AS backend_build
WORKDIR /src
COPY ./scrum-card-backend/go.mod ./scrum-card-backend/go.sum ./
RUN go mod download
COPY ./scrum-card-backend/ .
RUN mkdir -p /out && CGO_ENABLED=0 go build -o /out/scrumcards ./cmd/scrumcards/

FROM node:23.3-slim AS frontend_build
WORKDIR /app
COPY ./scrum-cards-ui/ .
RUN rm -rf node_modules build ; npm install && npm run build

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=backend_build /out/scrumcards /usr/local/bin/scrumcards

RUN apt-get update && apt-get install -y nginx
COPY --from=frontend_build /app/build/ /usr/share/nginx/html
COPY --from=frontend_build /app/nginx/nginx.conf /etc/nginx/sites-available/default

EXPOSE 80
CMD ["sh", "-c", "/usr/sbin/nginx -g \"daemon off;\" & scrumcards"]
