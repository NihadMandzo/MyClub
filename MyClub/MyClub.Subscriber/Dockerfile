FROM mcr.microsoft.com/dotnet/runtime:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MyClub.Subscriber/MyClub.Subscriber.csproj", "MyClub.Subscriber/"]
COPY ["MyClub.Model/MyClub.Model.csproj", "MyClub.Model/"]
RUN dotnet restore "MyClub.Subscriber/MyClub.Subscriber.csproj"
COPY . .
WORKDIR "/src/MyClub.Subscriber"
RUN dotnet build "MyClub.Subscriber.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MyClub.Subscriber.csproj" -c Release -o /app/publish 

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MyClub.Subscriber.dll"]
