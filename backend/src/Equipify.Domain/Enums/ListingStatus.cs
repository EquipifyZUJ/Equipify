namespace Equipify.Domain.Enums;

/// <summary>Lifecycle state of an equipment listing.</summary>
public enum ListingStatus
{
    /// <summary>Newly created, awaiting admin approval.</summary>
    Pending = 0,
    /// <summary>Approved and visible / rentable.</summary>
    Active = 1,
    /// <summary>Hidden by the owner or admin.</summary>
    Inactive = 2
}
