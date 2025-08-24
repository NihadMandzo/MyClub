# Build and run MyClub.WebAPI
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
# Copy the whole repo (use .dockerignore to trim context)
COPY . .
# Restore/build from the WebAPI project folder
WORKDIR /src/MyClub.WebAPI
RUN dotnet restore "MyClub.WebAPI.csproj"
RUN dotnet build "MyClub.WebAPI.csproj" -c Release -o /app/build

FROM build AS publish
WORKDIR /src/MyClub.WebAPI
RUN dotnet publish "MyClub.WebAPI.csproj" -c Release -o /app /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "MyClub.WebAPI.dll"]