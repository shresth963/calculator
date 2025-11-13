FROM node:18-alpine AS frontend-builder

WORKDIR /frontend
# Install deps first for better layer caching
COPY frontend/package.json frontend/yarn.lock ./
RUN corepack enable && yarn install --frozen-lockfile
# Copy source and build
COPY frontend /frontend
# Work around OpenSSL/webpack issue with newer Node
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN yarn build


FROM python:3.11-alpine
WORKDIR /app

# Install build deps (removed after pip install to keep image slim)
RUN apk add --no-cache --update --virtual .build-deps \
    gcc python3-dev libffi-dev openssl-dev libc-dev

COPY backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Remove build deps
RUN apk del .build-deps

# Copy backend source
COPY backend /app

# Copy built frontend into Flask static directory
COPY --from=frontend-builder /frontend/build /app/client

EXPOSE 5000

CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]