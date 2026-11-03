using EscapeHub.Application.Interfaces;
using EscapeHub.Infrastructure;
using EscapeHub.Infrastructure.Configuration;
using EscapeHub.Infrastructure.Messaging;
using EscapeHub.Worker.Configuration;
using EscapeHub.Worker.Email;
using EscapeHub.Worker.Handlers;
using EscapeHub.Worker.Loyalty;
using EscapeHub.Worker.Messaging;
using EscapeHub.Worker.Reminders;

EnvironmentConfiguration.LoadDotEnv();

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddPersistence(builder.Configuration);
builder.Services.AddSingleton(SmtpOptions.From(builder.Configuration));
builder.Services.AddSingleton(ReminderOptions.From(builder.Configuration));
builder.Services.AddSingleton(PointsSweepOptions.From(builder.Configuration));
builder.Services.AddSingleton<IEventPublisher, EventPublisher>();
builder.Services.AddSingleton<EmailSender>();
builder.Services.AddScoped<Notifier>();
builder.Services.AddScoped<BookingEventHandler>();
builder.Services.AddScoped<AccountEventHandler>();
builder.Services.AddScoped<EventDispatcher>();
builder.Services.AddHostedService<QueueConsumerService>();
builder.Services.AddHostedService<ReminderService>();
builder.Services.AddHostedService<PointsSweepService>();

await builder.Build().RunAsync();
