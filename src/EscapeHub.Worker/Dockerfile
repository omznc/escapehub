FROM mcr.microsoft.com/dotnet/sdk:8.0.425 AS build
WORKDIR /src

COPY EscapeHub.Domain/EscapeHub.Domain.csproj EscapeHub.Domain/
COPY EscapeHub.Application/EscapeHub.Application.csproj EscapeHub.Application/
COPY EscapeHub.Infrastructure/EscapeHub.Infrastructure.csproj EscapeHub.Infrastructure/
COPY EscapeHub.Worker/EscapeHub.Worker.csproj EscapeHub.Worker/
RUN dotnet restore EscapeHub.Worker/EscapeHub.Worker.csproj

COPY . .
RUN dotnet publish EscapeHub.Worker/EscapeHub.Worker.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/runtime:8.0.31 AS runtime
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "EscapeHub.Worker.dll"]
