using System;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public enum MembershipOperationType
    {
        NewPurchase,
        Renewal,
        GiftPurchase
    }

    public class UserMembershipUpsertRequest : PaymentRequest
    {
        [Required]
        public MembershipOperationType OperationType { get; set; }

        [Required]
        public int MembershipCardId { get; set; }

        // Only required for Renewal
        public int? PreviousMembershipId { get; set; }

        public ShippingRequest? Shipping { get; set; }

        // Only required for GiftPurchase
        [MaxLength(50)]
        public string? RecipientFirstName { get; set; }

        [MaxLength(50)]
        public string? RecipientLastName { get; set; }

        [EmailAddress]
        [MaxLength(100)]
        public string? RecipientEmail { get; set; }

        public bool PhysicalCardRequested { get; set; } = false;


        // Payment information
        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal PaymentAmount { get; set; }

        public bool Validate()
        {
            switch (OperationType)
            {
                case MembershipOperationType.Renewal:
                    if (!PreviousMembershipId.HasValue)
                        throw new ValidationException("PreviousMembershipId is required for renewal operations");
                    break;

                case MembershipOperationType.GiftPurchase:
                    if (string.IsNullOrEmpty(RecipientFirstName) || 
                        string.IsNullOrEmpty(RecipientLastName) || 
                        string.IsNullOrEmpty(RecipientEmail))
                        throw new ValidationException("Recipient information is required for gift purchases");
                    break;
            }

            if (PhysicalCardRequested && Shipping == null)
                throw new ValidationException("Shipping information is required when physical card is requested");

            return true;
        }
    }
} 