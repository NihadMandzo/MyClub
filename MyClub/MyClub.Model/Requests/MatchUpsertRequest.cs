using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MyClub.Model.Requests
{
    public class MatchUpsertRequest
    {
        [Required(ErrorMessage = "Datum utakmice je obavezan")]
        public DateTime MatchDate { get; set; }

        [Required(ErrorMessage = "Naziv protivnika je obavezan")]
        [MaxLength(100, ErrorMessage = "Naziv protivnika ne može biti duži od 100 karaktera")]
        public string OpponentName { get; set; }

        [Required(ErrorMessage = "Lokacija je obavezna")]
        [MaxLength(100, ErrorMessage = "Lokacija ne može biti duža od 100 karaktera")]
        public string Location { get; set; }

        [MaxLength(50, ErrorMessage = "Status ne može biti duži od 50 karaktera")]
        public string Status { get; set; } = "Scheduled";

        [MaxLength(500, ErrorMessage = "Opis ne može biti duži od 500 karaktera")]
        public string Description { get; set; }

        [Required(ErrorMessage = "Klub je obavezan")]
        public int ClubId { get; set; }
    }
} 