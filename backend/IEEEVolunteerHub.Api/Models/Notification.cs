using System;

namespace IEEEVolunteerHub.Api.Models;

public class Notification
{
    public int Id { get; set; }

    public string RecipientMemberId { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string Message { get; set; } = string.Empty;

    public string Type { get; set; } = "system";

    public bool IsRead { get; set; } = false;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? ReadAt { get; set; }

    public int? RelatedTaskId { get; set; }

    public int? RelatedEventId { get; set; }
}