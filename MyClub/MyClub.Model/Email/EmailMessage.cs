namespace MyClub.Model
{
    public class EmailMessage
    {
        public string To { get; set; }
        public string Subject { get; set; }
        public string Body { get; set; }
        public int OrderId { get; set; }
        public string OrderState { get; set; }
    }
}