FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj files first (layer caching)
COPY src/Equipify.Domain/Equipify.Domain.csproj src/Equipify.Domain/
COPY src/Equipify.Data/Equipify.Data.csproj src/Equipify.Data/
COPY src/Equipify.Service/Equipify.Service.csproj src/Equipify.Service/
COPY src/Equipify.Api/Equipify.Api.csproj src/Equipify.Api/
RUN dotnet restore src/Equipify.Api/Equipify.Api.csproj

# Copy everything and build
COPY src/ src/
RUN dotnet publish src/Equipify.Api/Equipify.Api.csproj -c Release -o /app/publish --no-restore

# ── Runtime ──
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 10000
ENV ASPNETCORE_URLS=http://0.0.0.0:10000
ENV ASPNETCORE_ENVIRONMENT=Production
ENTRYPOINT ["dotnet", "Equipify.Api.dll"]
