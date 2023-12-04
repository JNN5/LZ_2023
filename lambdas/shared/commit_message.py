import re


class CommitMessage:

  @staticmethod
  def generate(ticket_id: str):
   return f"ticket_id: [{ticket_id}]"
  
  @staticmethod
  def parse_ticket_id(msg: str):
    return re.search('ticket_id: \[(.*?)\]', msg).group(1)