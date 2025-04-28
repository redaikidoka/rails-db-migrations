CREATE TRIGGER tr_prevent_deletion
BEFORE DELETE ON happies
FOR EACH ROW
EXECUTE FUNCTION tr_prevent_deletion();