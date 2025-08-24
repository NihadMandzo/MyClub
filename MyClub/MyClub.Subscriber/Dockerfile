# Build and run MyClub.Subscriber (console service)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
WORKDIR /src/MyClub.Subscriber
RUN dotnet restore "MyClub.Subscriber.csproj"
RUN dotnet publish "MyClub.Subscriber.csproj" -c Release -o /app /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/runtime:8.0 AS final
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "MyClub.Subscriber.dll"]